/*
**  RingDotNet - .NET Extension for the Ring Programming Language
**  Hosts the .NET runtime (through hostfxr) inside the Ring process and forwards
**  requests to the managed bridge (RingDotNet.Bridge.dll).
**
**  The extension is intentionally thin. It has these functions:
**      dotnet_start(cMode)       start the runtime and load the bridge (once; the mode is "", "desktop", "web" or "all")
**      dotnet_invoke(cRequest)   send one request, get one response (binary-safe strings)
**      dotnet_info()             path of the hostfxr library that was used
**      dotnet_callbackrequest(), dotnet_callbackresult(cResult)
**                                the request of a Ring callback that .NET runs, and its result
**      dotnet_guard(nHandle), dotnet_unguard(pGuard), dotnet_pending(), dotnet_flush()
**                                managed pointers: when Ring drops a .NET object, its handle is queued, and the queued
**                                handles are released in groups
**  The request/response wire format is described in bridge/Bridge.cs and is
**  packed/unpacked by libraries/dotnetlib (Ring code).
*/

#ifndef _WIN32
	#ifndef _GNU_SOURCE
		#define _GNU_SOURCE   /* dladdr() */
	#endif
#endif
#include "ring.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* A path or message made of pieces: written into a buffer of nSize bytes and cut when it is longer (the last argument is NULL) */
#include <stdarg.h>
static void DnCat(char *cOut, size_t nSize, ...)
{
	va_list oArgs;
	const char *cPiece;
	size_t nLen = 0, nPiece;
	if (nSize == 0) { return; }
	va_start(oArgs,nSize);
	while ((cPiece = va_arg(oArgs,const char *)) != NULL) {
		nPiece = strlen(cPiece);
		if (nPiece > nSize - 1 - nLen) { nPiece = nSize - 1 - nLen; }
		memcpy(cOut + nLen,cPiece,nPiece);
		nLen += nPiece;
	}
	va_end(oArgs);
	cOut[nLen] = 0;
}

#ifdef _WIN32
	#include <windows.h>
	typedef wchar_t dn_char;
	#define DN_STR_(s) L##s
	#define DN_STR(s) DN_STR_(s)
	#define DN_CALLTYPE __stdcall
#else
	#include <dlfcn.h>
	#include <dirent.h>
	typedef char dn_char;
	#define DN_STR_(s) s
	#define DN_STR(s) DN_STR_(s)
	#define DN_CALLTYPE
#endif

#define DN_BRIDGE_ASSEMBLY  "RingDotNet.Bridge.dll"
#define DN_BRIDGE_CONFIG    "RingDotNet.Bridge.runtimeconfig.json"
#define DN_DESKTOP_CONFIG   "RingDotNet.Desktop.runtimeconfig.json"
#define DN_WEB_CONFIG       "RingDotNet.Web.runtimeconfig.json"
#define DN_ALL_CONFIG       "RingDotNet.All.runtimeconfig.json"
#define DN_BRIDGE_TYPE      "RingDotNet.Bridge, RingDotNet.Bridge"
#define DN_PATHSIZE         2048
#define DN_HDT_LOAD_ASSEMBLY_AND_GET_FUNCTION_POINTER 5
#define DN_UNMANAGEDCALLERSONLY ((const dn_char *) -1)

typedef int32_t (DN_CALLTYPE *dn_initialize_fn)(const dn_char *cConfig, const void *pParams, void **pHandle);
typedef int32_t (DN_CALLTYPE *dn_getdelegate_fn)(void *pHandle, int nType, void **pDelegate);
typedef int32_t (DN_CALLTYPE *dn_close_fn)(void *pHandle);
typedef int32_t (DN_CALLTYPE *dn_loadassembly_fn)(const dn_char *cAssembly, const dn_char *cType, const dn_char *cMethod, const dn_char *cDelegateType, void *pReserved, void **pDelegate);
typedef unsigned char *(DN_CALLTYPE *dn_invoke_fn)(const unsigned char *pRequest, int nSize, int *pOutSize);
typedef void (DN_CALLTYPE *dn_free_fn)(unsigned char *pBuffer);

/* The typed entries of the bridge (Bridge.Typed.cs): a property of a number, a yes/no or a text is read and written without a request text */
typedef struct {
	double nNumber ;
	const unsigned char *pText ;
	int32_t nTextLength ;
	int32_t nPad ;
} DnTyped ;
typedef int32_t (DN_CALLTYPE *dn_getprop_fn)(int64_t nHandle, const unsigned char *pName, int32_t nNameLength, DnTyped *pResult);
typedef int32_t (DN_CALLTYPE *dn_setpropn_fn)(int64_t nHandle, const unsigned char *pName, int32_t nNameLength, double nValue, DnTyped *pResult);
typedef int32_t (DN_CALLTYPE *dn_setpropt_fn)(int64_t nHandle, const unsigned char *pName, int32_t nNameLength, const unsigned char *pText, int32_t nTextLength, DnTyped *pResult);
/* an argument of a typed method call: a number (nKind 1) or a text (nKind 2) */
typedef struct {
	int32_t nKind ;
	int32_t nTextLength ;
	double nNumber ;
	const unsigned char *pText ;
} DnTypedArg ;
typedef int32_t (DN_CALLTYPE *dn_calltyped_fn)(int64_t nHandle, const unsigned char *pName, int32_t nNameLength, DnTypedArg *pArgs, int32_t nArgs, DnTyped *pResult);

/* Ring callbacks: the managed side asks us to run the Ring function dnDispatchCallback() */
static void *g_pVM = NULL ;
static int g_nDepth = 0 ;
static char *g_pCallbackRequest = NULL ;
static int g_nCallbackRequestSize = 0 ;
static char *g_pCallbackResult = NULL ;
static int g_nCallbackResultSize = 0 ;

static int g_nStarted = 0 ;
static int g_nDesktop = 0 ;
static dn_invoke_fn g_pInvoke = NULL ;
static dn_free_fn g_pFree = NULL ;
static dn_getprop_fn g_pGetProp = NULL ;
static dn_setpropn_fn g_pSetPropNumber = NULL ;
static dn_setpropt_fn g_pSetPropText = NULL ;
static dn_calltyped_fn g_pCallTyped = NULL ;
static char g_cHostFxr[DN_PATHSIZE] = "" ;
static char g_cError[DN_PATHSIZE] = "" ;

static void ringdotnet_seterror ( const char *cMsg, const char *cDetail )
{
	DnCat(g_cError,DN_PATHSIZE,cMsg,cDetail ? ": " : "",cDetail ? cDetail : "",NULL);
}

/* Folder that contains this extension library (the bridge is deployed next to it) */
static int ringdotnet_modulefolder ( char *cFolder, size_t nSize )
{
	char *p, *p2 ;
#ifdef _WIN32
	HMODULE hModule = NULL ;
	if ( ! GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,(LPCSTR) ringdotnet_modulefolder,&hModule) ) {
		return 0 ;
	}
	if ( ! GetModuleFileNameA(hModule,cFolder,(DWORD) nSize) ) {
		return 0 ;
	}
#else
	Dl_info oInfo ;
	if ( ! dladdr((void *) ringdotnet_modulefolder,&oInfo) || ! oInfo.dli_fname ) {
		return 0 ;
	}
	DnCat(cFolder,nSize,oInfo.dli_fname,NULL);
#endif
	p = strrchr(cFolder,'/');
	p2 = strrchr(cFolder,'\\');
	if ( p2 > p ) {
		p = p2 ;
	}
	if ( ! p ) {
		return 0 ;
	}
	*p = '\0' ;
	return 1 ;
}

/* Convert a UTF-8 path to the host's native character type */
static void ringdotnet_tochar ( const char *cSrc, dn_char *cDest, size_t nSize )
{
#ifdef _WIN32
	if ( ! MultiByteToWideChar(CP_UTF8,0,cSrc,-1,cDest,(int) nSize) ) {
		cDest[0] = 0 ;
	}
#else
	DnCat(cDest,nSize,cSrc,NULL);
#endif
}

static int ringdotnet_fileexists ( const char *cPath )
{
	FILE *fp = fopen(cPath,"rb");
	if ( fp ) {
		fclose(fp);
		return 1 ;
	}
	return 0 ;
}

/* Compare two "major.minor.patch[-tag]" versions, a pre-release is lower than the release */
static int ringdotnet_vercmp ( const char *a, const char *b )
{
	int x[3] = {0,0,0}, y[3] = {0,0,0}, i ;
	sscanf(a,"%d.%d.%d",&x[0],&x[1],&x[2]);
	sscanf(b,"%d.%d.%d",&y[0],&y[1],&y[2]);
	for ( i = 0 ; i < 3 ; i++ ) {
		if ( x[i] != y[i] ) {
			return x[i] - y[i] ;
		}
	}
	return (strchr(a,'-') ? 0 : 1) - (strchr(b,'-') ? 0 : 1) ;
}

/* Search <root>/host/fxr/<highest version>/hostfxr library */
static int ringdotnet_findinroot ( const char *cRoot, char *cOut, size_t nSize )
{
	char cBest[128] = "", cDir[DN_PATHSIZE] ;
	DnCat(cDir,DN_PATHSIZE,cRoot,"/host/fxr",NULL);
#ifdef _WIN32
	{
		WIN32_FIND_DATAA oData ;
		char cPattern[DN_PATHSIZE] ;
		HANDLE hFind ;
		DnCat(cPattern,DN_PATHSIZE,cDir,"/*",NULL);
		hFind = FindFirstFileA(cPattern,&oData);
		if ( hFind == INVALID_HANDLE_VALUE ) {
			return 0 ;
		}
		do {
			if ( (oData.cFileName[0] >= '0') && (oData.cFileName[0] <= '9') ) {
				if ( (cBest[0] == 0) || (ringdotnet_vercmp(oData.cFileName,cBest) > 0) ) {
					DnCat(cBest,sizeof(cBest),oData.cFileName,NULL);
				}
			}
		} while ( FindNextFileA(hFind,&oData) );
		FindClose(hFind);
	}
	if ( cBest[0] == 0 ) {
		return 0 ;
	}
	DnCat(cOut,nSize,cDir,"/",cBest,"/hostfxr.dll",NULL);
#else
	{
		DIR *pDir = opendir(cDir);
		struct dirent *pEntry ;
		if ( ! pDir ) {
			return 0 ;
		}
		while ( (pEntry = readdir(pDir)) != NULL ) {
			if ( (pEntry->d_name[0] >= '0') && (pEntry->d_name[0] <= '9') ) {
				if ( (cBest[0] == 0) || (ringdotnet_vercmp(pEntry->d_name,cBest) > 0) ) {
					DnCat(cBest,sizeof(cBest),pEntry->d_name,NULL);
				}
			}
		}
		closedir(pDir);
		if ( cBest[0] == 0 ) {
			return 0 ;
		}
	#ifdef __APPLE__
		DnCat(cOut,nSize,cDir,"/",cBest,"/libhostfxr.dylib",NULL);
	#else
		DnCat(cOut,nSize,cDir,"/",cBest,"/libhostfxr.so",NULL);
	#endif
	}
#endif
	return ringdotnet_fileexists(cOut) ;
}

/* Locate hostfxr: DOTNET_ROOT first, then the default install folders */
static int ringdotnet_findhostfxr ( char *cOut, size_t nSize )
{
	const char *cRoot = getenv("DOTNET_ROOT");
	if ( cRoot && cRoot[0] && ringdotnet_findinroot(cRoot,cOut,nSize) ) {
		return 1 ;
	}
#ifdef _WIN32
	cRoot = getenv("ProgramFiles");
	if ( cRoot ) {
		char cTemp[DN_PATHSIZE] ;
		DnCat(cTemp,DN_PATHSIZE,cRoot,"/dotnet",NULL);
		if ( ringdotnet_findinroot(cTemp,cOut,nSize) ) {
			return 1 ;
		}
	}
	return ringdotnet_findinroot("C:/Program Files/dotnet",cOut,nSize) ;
#else
	return ringdotnet_findinroot("/usr/share/dotnet",cOut,nSize) ||
	       ringdotnet_findinroot("/usr/lib/dotnet",cOut,nSize) ||
	       ringdotnet_findinroot("/usr/local/share/dotnet",cOut,nSize) ||
	       ringdotnet_findinroot("/opt/homebrew/opt/dotnet/libexec",cOut,nSize) ;
#endif
}

#ifdef _WIN32
	#define DN_SYM(lib,name) ((void *) GetProcAddress((HMODULE) (lib),name))
#else
	#define DN_SYM(lib,name) dlsym(lib,name)
#endif

static void ringdotnet_setresult ( const char *pData, int nSize )
{
	free(g_pCallbackResult);
	g_pCallbackResult = (char *) malloc(nSize > 0 ? nSize : 1);
	if ( g_pCallbackResult && (nSize > 0) ) {
		memcpy(g_pCallbackResult,pData,nSize);
	}
	g_nCallbackResultSize = g_pCallbackResult ? nSize : 0 ;
}

/* Called by the managed bridge: run a Ring callback and return the size of the packed result */
static int DN_CALLTYPE ringdotnet_callback ( const unsigned char *pRequest, int nSize, unsigned char *pOut, int nCapacity )
{
	static const char cNoRing[] = "e42:No active Ring call to run the callback in" ;
	if ( pRequest ) {
		if ( (! g_pVM) || (g_nDepth == 0) ) {
			ringdotnet_setresult(cNoRing,(int) sizeof(cNoRing) - 1);
		} else {
			free(g_pCallbackRequest);
			g_pCallbackRequest = (char *) malloc(nSize > 0 ? nSize : 1);
			memcpy(g_pCallbackRequest,pRequest,nSize);
			g_nCallbackRequestSize = nSize ;
			ringdotnet_setresult("z0:",3);
			{
				/* Run dnDispatchCallback() to completion (no eval: the code of the callback was compiled when dnCallback() was called) */
				VM *pVM = (VM *) g_pVM ;
				unsigned int nSP = pVM->nSP, nFuncSP = pVM->nFuncSP ;
				ring_vm_runcode(pVM,"dnDispatchCallback()");
				pVM->nSP = nSP ;
				pVM->nFuncSP = nFuncSP ;
			}
		}
	}
	if ( pOut && (g_nCallbackResultSize <= nCapacity) ) {
		memcpy(pOut,g_pCallbackResult,g_nCallbackResultSize);
	}
	return g_nCallbackResultSize ;
}

/* Start the runtime and bind the bridge entry points, returns 1 on success */
static int ringdotnet_startruntime ( const char *cMode )
{
	char cFolder[DN_PATHSIZE], cPath[DN_PATHSIZE], cNum[32] ;
	dn_char wPath[DN_PATHSIZE], wConfig[DN_PATHSIZE] ;
	void *pLib, *pHandle = NULL, *pLoader = NULL, *pFn = NULL ;
	dn_initialize_fn pInit ;
	dn_getdelegate_fn pGetDelegate ;
	dn_close_fn pClose ;
	dn_loadassembly_fn pLoad ;
	int32_t nRC ;

	if ( g_nStarted ) {
		return 1 ;
	}
	if ( ! ringdotnet_modulefolder(cFolder,sizeof(cFolder)) ) {
		ringdotnet_seterror("Can't locate the ring_dotnet library folder",NULL);
		return 0 ;
	}
	DnCat(cPath,DN_PATHSIZE,cFolder,"/",DN_BRIDGE_ASSEMBLY,NULL);
	if ( ! ringdotnet_fileexists(cPath) ) {
		/* On Linux and macOS the library is in ring/lib and the package files (the bridge, the other assemblies) are in ring/bin */
		DnCat(cPath,DN_PATHSIZE,cFolder,"/../bin/",DN_BRIDGE_ASSEMBLY,NULL);
		if ( ringdotnet_fileexists(cPath) ) {
			DnCat(cPath,DN_PATHSIZE,cFolder,"/../bin",NULL);
			DnCat(cFolder,DN_PATHSIZE,cPath,NULL);
		}
		DnCat(cPath,DN_PATHSIZE,cFolder,"/",DN_BRIDGE_ASSEMBLY,NULL);
	}
	if ( ! ringdotnet_fileexists(cPath) ) {
		ringdotnet_seterror("Bridge assembly not found",cPath);
		return 0 ;
	}
	if ( ! ringdotnet_findhostfxr(g_cHostFxr,sizeof(g_cHostFxr)) ) {
		ringdotnet_seterror(".NET runtime not found (install the .NET runtime or set DOTNET_ROOT)",NULL);
		return 0 ;
	}
#ifdef _WIN32
	pLib = (void *) LoadLibraryA(g_cHostFxr);
#else
	pLib = dlopen(g_cHostFxr,RTLD_LAZY | RTLD_LOCAL);
#endif
	if ( ! pLib ) {
		ringdotnet_seterror("Can't load hostfxr",g_cHostFxr);
		return 0 ;
	}
	pInit = (dn_initialize_fn) DN_SYM(pLib,"hostfxr_initialize_for_runtime_config");
	pGetDelegate = (dn_getdelegate_fn) DN_SYM(pLib,"hostfxr_get_runtime_delegate");
	pClose = (dn_close_fn) DN_SYM(pLib,"hostfxr_close");
	if ( (! pInit) || (! pGetDelegate) || (! pClose) ) {
		ringdotnet_seterror("hostfxr does not export the hosting API",g_cHostFxr);
		return 0 ;
	}
	if ( cMode && ((strcmp(cMode,"desktop") == 0) || (strcmp(cMode,"all") == 0)) ) {
		DnCat(cPath,DN_PATHSIZE,cFolder,"/",(strcmp(cMode,"all") == 0) ? DN_ALL_CONFIG : DN_DESKTOP_CONFIG,NULL);
	#ifdef _WIN32
		/* Windows Forms needs the thread that runs the UI to be an STA thread */
		CoInitializeEx(NULL,COINIT_APARTMENTTHREADED);
	#endif
	} else if ( cMode && (strcmp(cMode,"web") == 0) ) {
		DnCat(cPath,DN_PATHSIZE,cFolder,"/",DN_WEB_CONFIG,NULL);
	} else {
		DnCat(cPath,DN_PATHSIZE,cFolder,"/",DN_BRIDGE_CONFIG,NULL);
	}
	ringdotnet_tochar(cPath,wConfig,DN_PATHSIZE);
	nRC = pInit(wConfig,NULL,&pHandle);
	if ( (nRC < 0) || (! pHandle) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("hostfxr_initialize_for_runtime_config failed",cNum);
		if ( pHandle ) {
			pClose(pHandle);
		}
		return 0 ;
	}
	nRC = pGetDelegate(pHandle,DN_HDT_LOAD_ASSEMBLY_AND_GET_FUNCTION_POINTER,&pLoader);
	pClose(pHandle);
	if ( (nRC < 0) || (! pLoader) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("hostfxr_get_runtime_delegate failed",cNum);
		return 0 ;
	}
	pLoad = (dn_loadassembly_fn) pLoader ;
	DnCat(cPath,DN_PATHSIZE,cFolder,"/",DN_BRIDGE_ASSEMBLY,NULL);
	ringdotnet_tochar(cPath,wPath,DN_PATHSIZE);
	nRC = pLoad(wPath,DN_STR(DN_BRIDGE_TYPE),DN_STR("Invoke"),DN_UNMANAGEDCALLERSONLY,NULL,&pFn);
	if ( (nRC < 0) || (! pFn) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("Can't bind Bridge.Invoke",cNum);
		return 0 ;
	}
	g_pInvoke = (dn_invoke_fn) pFn ;
	pFn = NULL ;
	nRC = pLoad(wPath,DN_STR(DN_BRIDGE_TYPE),DN_STR("Free"),DN_UNMANAGEDCALLERSONLY,NULL,&pFn);
	if ( (nRC < 0) || (! pFn) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("Can't bind Bridge.Free",cNum);
		return 0 ;
	}
	g_pFree = (dn_free_fn) pFn ;
	pFn = NULL ;
	nRC = pLoad(wPath,DN_STR(DN_BRIDGE_TYPE),DN_STR("GetProp"),DN_UNMANAGEDCALLERSONLY,NULL,&pFn);
	if ( (nRC < 0) || (! pFn) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("Can't bind Bridge.GetProp",cNum);
		return 0 ;
	}
	g_pGetProp = (dn_getprop_fn) pFn ;
	pFn = NULL ;
	nRC = pLoad(wPath,DN_STR(DN_BRIDGE_TYPE),DN_STR("SetPropNumber"),DN_UNMANAGEDCALLERSONLY,NULL,&pFn);
	if ( (nRC < 0) || (! pFn) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("Can't bind Bridge.SetPropNumber",cNum);
		return 0 ;
	}
	g_pSetPropNumber = (dn_setpropn_fn) pFn ;
	pFn = NULL ;
	nRC = pLoad(wPath,DN_STR(DN_BRIDGE_TYPE),DN_STR("SetPropText"),DN_UNMANAGEDCALLERSONLY,NULL,&pFn);
	if ( (nRC < 0) || (! pFn) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("Can't bind Bridge.SetPropText",cNum);
		return 0 ;
	}
	g_pSetPropText = (dn_setpropt_fn) pFn ;
	pFn = NULL ;
	nRC = pLoad(wPath,DN_STR(DN_BRIDGE_TYPE),DN_STR("CallTyped"),DN_UNMANAGEDCALLERSONLY,NULL,&pFn);
	if ( (nRC < 0) || (! pFn) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("Can't bind Bridge.CallTyped",cNum);
		return 0 ;
	}
	g_pCallTyped = (dn_calltyped_fn) pFn ;
	pFn = NULL ;
	nRC = pLoad(wPath,DN_STR(DN_BRIDGE_TYPE),DN_STR("SetCallback"),DN_UNMANAGEDCALLERSONLY,NULL,&pFn);
	if ( (nRC < 0) || (! pFn) ) {
		snprintf(cNum,sizeof(cNum),"0x%08X",(unsigned) nRC);
		ringdotnet_seterror("Can't bind Bridge.SetCallback",cNum);
		return 0 ;
	}
	((void (DN_CALLTYPE *)(void *)) pFn)((void *) ringdotnet_callback);
	g_nStarted = 1 ;
	g_nDesktop = (cMode && ((strcmp(cMode,"desktop") == 0) || (strcmp(cMode,"web") == 0) || (strcmp(cMode,"all") == 0))) ;
	return 1 ;
}

/* dotnet_start([cMode]) --> 1   (cMode: "desktop" adds Windows Forms / WPF, "web" adds ASP.NET Core, "all" both. The runtime starts in one mode only,
   so the mode must be chosen before the first .NET call: using { } does it from the names of the namespaces) */
RING_FUNC(ring_dotnet_start)
{
	const char *cMode = NULL ;
	if ( RING_API_PARACOUNT > 1 ) {
		RING_API_ERROR(RING_API_BADPARACOUNT);
		return ;
	}
	if ( RING_API_PARACOUNT == 1 ) {
		if ( ! RING_API_ISSTRING(1) ) {
			RING_API_ERROR(RING_API_BADPARATYPE);
			return ;
		}
		cMode = RING_API_GETSTRING(1);
		if ( g_nStarted && ((strcmp(cMode,"desktop") == 0) || (strcmp(cMode,"web") == 0) || (strcmp(cMode,"all") == 0)) && (! g_nDesktop) ) {
			RING_API_ERROR("The runtime mode (desktop, web or all) must be chosen before any other .NET call: put the using { } block first, or call dnUseDesktop(), dnUseWeb() or dnUseAll() first");
			return ;
		}
	}
	if ( ! ringdotnet_startruntime(cMode) ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	RING_API_RETNUMBER(1);
}

/*
**  Guards: a Ring object that owns a .NET handle keeps a managed C pointer (a "guard") with the number of the handle. Ring frees the
**  pointer when the last copy of the object is gone, and the number is put in a list. The list is sent to the bridge (one request for
**  many handles) by the next dotnet_invoke() once it has 32 handles (or by dotnet_flush()): the free function itself never calls .NET, because Ring may run
**  it at any moment, even when the program ends.
*/
typedef struct { double nHandle ; } DNGuard ;
static double *g_aPending = NULL ;
static int g_nPending = 0 ;
static int g_nPendingCapacity = 0 ;
#define DN_FLUSH_AT 32

static void ringdotnet_freeguard ( void *pState, void *pPointer )
{
	DNGuard *pGuard = (DNGuard *) pPointer ;
	if ( pGuard->nHandle > 0 ) {
		if ( g_nPending == g_nPendingCapacity ) {
			int nCapacity = g_nPendingCapacity ? g_nPendingCapacity * 2 : 256 ;
			double *pNew = (double *) realloc(g_aPending,nCapacity * sizeof(double));
			if ( pNew ) {
				g_aPending = pNew ;
				g_nPendingCapacity = nCapacity ;
			}
		}
		if ( g_nPending < g_nPendingCapacity ) {
			g_aPending[g_nPending++] = pGuard->nHandle ;
		}
	}
	free(pGuard);
}

/* send the handles of the objects that were freed: releasemany(n1,n2,...) */
static void ringdotnet_flushpending ( void )
{
	char *pRequest, *p ;
	unsigned char *pOut ;
	int nOutSize = 0, x, nLen ;
	if ( g_nPending == 0 || ! g_pInvoke ) {
		return ;
	}
	pRequest = (char *) malloc(32 + (size_t) g_nPending * 32);
	if ( ! pRequest ) {
		return ;
	}
	p = pRequest ;
	p += sprintf(p,"s11:releasemany");
	for ( x = 0 ; x < g_nPending ; x++ ) {
		char cNum[32] ;
		nLen = sprintf(cNum,"%.0f",g_aPending[x]);
		p += sprintf(p,"n%d:%s",nLen,cNum);
	}
	g_nPending = 0 ;
	pOut = g_pInvoke((const unsigned char *) pRequest,(int) (p - pRequest),&nOutSize);
	if ( pOut ) {
		g_pFree(pOut);
	}
	free(pRequest);
}

/* dotnet_guard(nHandle) --> a managed pointer that releases the handle when Ring frees it */
RING_FUNC(ring_dotnet_guard)
{
	DNGuard *pGuard ;
	if ( RING_API_PARACOUNT != 1 ) {
		RING_API_ERROR(RING_API_MISS1PARA);
		return ;
	}
	if ( ! RING_API_ISNUMBER(1) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	pGuard = (DNGuard *) malloc(sizeof(DNGuard));
	if ( ! pGuard ) {
		RING_API_ERROR(RING_OOM);
		return ;
	}
	pGuard->nHandle = RING_API_GETNUMBER(1) ;
	RING_API_RETMANAGEDCPOINTER(pGuard,"dotnet_guard",ringdotnet_freeguard);
}

/* dotnet_unguard(oGuard): the guard no longer releases the handle (the handle was released or belongs to somebody else) */
RING_FUNC(ring_dotnet_unguard)
{
	DNGuard *pGuard ;
	if ( RING_API_PARACOUNT != 1 ) {
		RING_API_ERROR(RING_API_MISS1PARA);
		return ;
	}
	if ( ! RING_API_ISCPOINTER(1) ) {
		return ;
	}
	pGuard = (DNGuard *) RING_API_GETCPOINTER(1,"dotnet_guard");
	if ( pGuard ) {
		pGuard->nHandle = 0 ;
	}
}

/* dotnet_flush(): release the handles of the freed objects now */
RING_FUNC(ring_dotnet_flush)
{
	ringdotnet_flushpending();
}

/* dotnet_pending() --> the number of freed objects that wait for their handle to be released */
RING_FUNC(ring_dotnet_pending)
{
	RING_API_RETNUMBER(g_nPending);
}

/* dotnet_invoke(cRequest) --> cResponse */
RING_FUNC(ring_dotnet_invoke)
{
	unsigned char *pOut ;
	void *pOldVM ;
	int nOutSize = 0 ;
	if ( RING_API_PARACOUNT != 1 ) {
		RING_API_ERROR(RING_API_MISS1PARA);
		return ;
	}
	if ( ! RING_API_ISSTRING(1) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( ! ringdotnet_startruntime(NULL) ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	/* Keep the output order between Ring (C stdio) and .NET (Console) */
	fflush(stdout);
	if ( g_nPending >= DN_FLUSH_AT ) {
		ringdotnet_flushpending();
	}
	pOldVM = g_pVM ;
	g_pVM = pPointer ;
	g_nDepth++ ;
	pOut = g_pInvoke((const unsigned char *) RING_API_GETSTRING(1),(int) RING_API_GETSTRINGSIZE(1),&nOutSize);
	g_nDepth-- ;
	g_pVM = pOldVM ;
	if ( ! pOut ) {
		RING_API_ERROR("The .NET bridge returned no response");
		return ;
	}
	RING_API_RETSTRING2((const char *) pOut,nOutSize);
	g_pFree(pOut);
}

/* dotnet_info() --> hostfxr path ("" before the runtime starts) */
RING_FUNC(ring_dotnet_info)
{
	RING_API_RETSTRING(g_cHostFxr);
}

/* ---------------------------------------------------------------- dotnet_call: a call of a member, packed and read in C
**
**  dotnet_call(cOperation, nHandle or cTypeName, cName, arg1, arg2, ...)     the answer is a text, a number or a yes/no
**  dotnet_callv(...)                                                         a method that returns nothing: 1
**  dotnet_callo(...)                                                         a method that returns an object
**  dotnet_callmethod(cOperation, target, cName, aArguments)                  any answer (like dotnet_calla), the arguments are the items of one list
**    cOperation and cName are ready wire items ("s4:call", "s8:Contains"), the target is the handle of the object (0: the null object) or,
**    for a static method, the name of the type (the handle is remembered in this file). The arguments are packed here: texts, numbers,
**    lists (also lists of lists), .NET objects (their handle) and callbacks (their code), like the Ring function dnPackItem does.
**    The request is the same text that dnSend makes in Ring; the answer is read here:
**      dotnet_call:   a text, a number or a yes/no  --> that value
**      dotnet_callv:  1
**      dotnet_callo:  an object --> "<handle>|<type>|<base type>..." (a text: dnObj wraps it); null --> 0
**      dotnet_calla:  any answer: a text, a number or a yes/no --> that value; an object --> the list [2, "<handle>|<type>..."]
**      a .NET error is raised as a Ring error; any other answer --> the list [1, answer] (dnFinish reads it)
*/

/* A growing text: it starts in the buffer of the caller (1 KB) and moves to the heap when it needs more */
typedef struct {
	char *p ;
	size_t nSize ;
	size_t nCapacity ;
	char cLocal[1024] ;
} DnBuf ;

static void dnbuf_init ( DnBuf *b )
{
	b->p = b->cLocal ;
	b->nSize = 0 ;
	b->nCapacity = sizeof(b->cLocal) ;
}

static void dnbuf_free ( DnBuf *b )
{
	if ( b->p != b->cLocal ) {
		free(b->p);
	}
}

static int dnbuf_need ( DnBuf *b, size_t nExtra )
{
	if ( b->nSize + nExtra + 1 > b->nCapacity ) {
		size_t nNew = b->nCapacity * 2 ;
		char *pNew ;
		while ( b->nSize + nExtra + 1 > nNew ) {
			nNew *= 2 ;
		}
		if ( b->p == b->cLocal ) {
			pNew = (char *) malloc(nNew);
			if ( pNew ) {
				memcpy(pNew,b->p,b->nSize);
			}
		} else {
			pNew = (char *) realloc(b->p,nNew);
		}
		if ( ! pNew ) {
			return 0 ;
		}
		b->p = pNew ;
		b->nCapacity = nNew ;
	}
	return 1 ;
}

static int dnbuf_add ( DnBuf *b, const char *pData, size_t nSize )
{
	if ( ! dnbuf_need(b,nSize) ) {
		return 0 ;
	}
	memcpy(b->p + b->nSize,pData,nSize);
	b->nSize += nSize ;
	return 1 ;
}

/* one item: <tag><length>:<data> */
static int dnbuf_item ( DnBuf *b, char cTag, const char *pData, size_t nSize )
{
	char cHead[32] ;
	int nHead = sprintf(cHead,"%c%u:",cTag,(unsigned int) nSize);
	return dnbuf_add(b,cHead,(size_t) nHead) && dnbuf_add(b,pData,nSize) ;
}

static int dnbuf_number ( DnBuf *b, double nValue )
{
	char cNum[48] ;
	if ( (nValue == floor(nValue)) && (fabs(nValue) < 1000000000000.0) ) {
		int nLen = sprintf(cNum,"%.0f",nValue);
		return dnbuf_item(b,'n',cNum,(size_t) nLen) ;
	}
	/* other numbers travel as the 8 bytes of the double (no loss of precision) */
	return dnbuf_item(b,'d',(const char *) &nValue,8) ;
}

/* the handle item of an object (o<length>:<handle>) or the null item */
static int dnbuf_handle ( DnBuf *b, double nHandle )
{
	char cNum[48] ;
	int nLen ;
	if ( nHandle == 0 ) {
		return dnbuf_add(b,"z0:",3) ;
	}
	nLen = sprintf(cNum,"%.0f",nHandle);
	return dnbuf_item(b,'o',cNum,(size_t) nLen) ;
}

/* the variable list of an attribute of an object (by its lower case name), or NULL */
static List *ringdotnet_attribute ( List *pObject, const char *cName )
{
	List *pData = RING_OBJECT_GETOBJECTDATA(pObject) ;
	unsigned int x, nSize = ring_list_getsize(pData) ;
	for ( x = 1 ; x <= nSize ; x++ ) {
		List *pVar ;
		if ( ! ring_list_islist(pData,x) ) {
			continue ;
		}
		pVar = ring_list_getlist(pData,x);
		if ( ring_list_getsize(pVar) >= RING_VAR_VALUE && ring_list_isstring(pVar,RING_VAR_NAME) &&
		     (strcmp(ring_list_getstring(pVar,RING_VAR_NAME),cName) == 0) ) {
			return pVar ;
		}
	}
	return NULL ;
}

static int dn_packlist ( DnBuf *b, List *pList ) ;

/* a Ring object that is an argument: a callback (the attribute cCode) or a .NET object (the attribute nHandle) */
static int dn_packobject ( DnBuf *b, List *pObject )
{
	List *pVar = ringdotnet_attribute(pObject,"ccode") ;
	if ( pVar && ring_list_isstring(pVar,RING_VAR_VALUE) ) {
		return dnbuf_item(b,'c',ring_list_getstring(pVar,RING_VAR_VALUE),(size_t) ring_list_getstringsize(pVar,RING_VAR_VALUE)) ;
	}
	pVar = ringdotnet_attribute(pObject,"nhandle");
	if ( pVar && ring_list_isnumber(pVar,RING_VAR_VALUE) ) {
		return dnbuf_handle(b,ring_list_getdouble(pVar,RING_VAR_VALUE)) ;
	}
	return -1 ;
}

/* a list item that is a list or an object */
static int dn_packsub ( DnBuf *b, List *pSub )
{
	if ( ring_list_isobject(pSub) ) {
		return dn_packobject(b,pSub) ;
	}
	return dn_packlist(b,pSub) ;
}

/* the items of a list, one after the other: 1 packed, 0 no memory, -1 an item that can not be sent */
static int dn_packitems ( DnBuf *b, List *pList )
{
	unsigned int x, nSize = ring_list_getsize(pList) ;
	int nResult = 1 ;
	for ( x = 1 ; x <= nSize && nResult > 0 ; x++ ) {
		if ( ring_list_isstring(pList,x) ) {
			nResult = dnbuf_item(b,'s',ring_list_getstring(pList,x),(size_t) ring_list_getstringsize(pList,x)) ;
		} else if ( ring_list_isnumber(pList,x) ) {
			nResult = dnbuf_number(b,ring_list_getdouble(pList,x)) ;
		} else if ( ring_list_islist(pList,x) ) {
			nResult = dn_packsub(b,ring_list_getlist(pList,x)) ;
		} else {
			nResult = -1 ;
		}
	}
	return nResult ;
}

/* a list: the item 'l' with the items inside */
static int dn_packlist ( DnBuf *b, List *pList )
{
	DnBuf oInner ;
	int nResult ;
	dnbuf_init(&oInner);
	nResult = dn_packitems(&oInner,pList) ;
	if ( nResult > 0 ) {
		nResult = dnbuf_item(b,'l',oInner.p,oInner.nSize) ;
	}
	dnbuf_free(&oInner);
	return nResult ;
}

/* a parameter of the Ring function: 1 packed, 0 no memory, -1 not a type that can be sent */
static int dn_packparam ( DnBuf *b, void *pPointer, int x )
{
	if ( RING_API_ISSTRING(x) ) {
		return dnbuf_item(b,'s',RING_API_GETSTRING(x),(size_t) RING_API_GETSTRINGSIZE(x)) ;
	}
	if ( RING_API_ISNUMBER(x) ) {
		return dnbuf_number(b,RING_API_GETNUMBER(x)) ;
	}
	if ( RING_API_ISLIST(x) ) {
		return dn_packsub(b,RING_API_GETLIST(x)) ;
	}
	return -1 ;
}

/* The handle of the type object of a type name, for the static methods: dotnet_call may be given the name of the type (a text) instead of
   a handle. The first call asks the bridge ("type" request), the handle is remembered here, so that later calls do not look it up in Ring. */
#define DN_TYPECACHE 512
static struct {
	char *cName ;
	int nLen ;
	double nHandle ;
} g_aTypeCache[DN_TYPECACHE] ;

static int ringdotnet_typehandle ( const char *cName, int nLen, double *pHandle )
{
	unsigned int nHash = 5381, nSlot ;
	int x, nTry ;
	DnBuf oRequest ;
	const unsigned char *pOut ;
	int nOutSize = 0 ;
	for ( x = 0 ; x < nLen ; x++ ) {
		nHash = nHash * 33 + (unsigned char) cName[x] ;
	}
	nSlot = nHash % DN_TYPECACHE ;
	for ( nTry = 0 ; nTry < DN_TYPECACHE ; nTry++ ) {
		unsigned int nAt = (nSlot + (unsigned int) nTry) % DN_TYPECACHE ;
		if ( ! g_aTypeCache[nAt].cName ) {
			nSlot = nAt ;
			break ;
		}
		if ( (g_aTypeCache[nAt].nLen == nLen) && (memcmp(g_aTypeCache[nAt].cName,cName,(size_t) nLen) == 0) ) {
			*pHandle = g_aTypeCache[nAt].nHandle ;
			return 1 ;
		}
		if ( nTry == DN_TYPECACHE - 1 ) {
			nSlot = DN_TYPECACHE ;          /* the table is full: ask every time */
		}
	}
	dnbuf_init(&oRequest);
	if ( ! (dnbuf_add(&oRequest,"s4:type",7) && dnbuf_item(&oRequest,'s',cName,(size_t) nLen)) ) {
		dnbuf_free(&oRequest);
		return 0 ;
	}
	g_nDepth++ ;
	pOut = g_pInvoke((const unsigned char *) oRequest.p,(int) oRequest.nSize,&nOutSize);
	g_nDepth-- ;
	dnbuf_free(&oRequest);
	if ( ! pOut ) {
		return 0 ;
	}
	/* "o<length>:<handle>|<type>..." */
	if ( (nOutSize > 3) && (pOut[0] == 'o') ) {
		int nColon = 1 ;
		double nValue = 0 ;
		while ( (nColon < nOutSize) && (pOut[nColon] != ':') ) {
			nColon++ ;
		}
		nColon++ ;
		while ( (nColon < nOutSize) && (pOut[nColon] >= '0') && (pOut[nColon] <= '9') ) {
			nValue = nValue * 10 + (pOut[nColon] - '0') ;
			nColon++ ;
		}
		g_pFree((void *) pOut);
		*pHandle = nValue ;
		if ( (nValue > 0) && (nSlot < DN_TYPECACHE) ) {
			g_aTypeCache[nSlot].cName = (char *) malloc((size_t) nLen + 1);
			if ( g_aTypeCache[nSlot].cName ) {
				memcpy(g_aTypeCache[nSlot].cName,cName,(size_t) nLen);
				g_aTypeCache[nSlot].nLen = nLen ;
				g_aTypeCache[nSlot].nHandle = nValue ;
			}
		}
		return nValue > 0 ;
	}
	g_pFree((void *) pOut);
	return 0 ;
}

#define DN_MODE_VALUE 0
#define DN_MODE_VOID 1
#define DN_MODE_OBJECT 2
#define DN_MODE_ANY 3

/* The answer of a request (one item, <tag><length>:<data>) as the value of the Ring function that is running: pOut is freed here */
static void ringdotnet_answer ( void *pPointer, int nMode, const unsigned char *pOut, int nOutSize )
{
	int nLen, nColon ;
	char cTag, cNum[48] ;
	/* one item: <tag><length>:<data> */
	cTag = (nOutSize > 0) ? (char) pOut[0] : 0 ;
	nLen = 0 ;
	nColon = 1 ;
	while ( (nColon < nOutSize) && (pOut[nColon] != ':') && (pOut[nColon] >= '0') && (pOut[nColon] <= '9') && (nColon < 10) ) {
		nLen = nLen * 10 + (pOut[nColon] - '0') ;
		nColon++ ;
	}
	if ( (nColon < nOutSize) && (pOut[nColon] == ':') && (nOutSize == nColon + 1 + nLen) ) {
		const char *pBody = (const char *) pOut + nColon + 1 ;
		if ( nMode == DN_MODE_VOID && cTag != 'e' ) {
			RING_API_RETNUMBER(1);
			g_pFree((void *) pOut);
			return ;
		}
		if ( nMode == DN_MODE_OBJECT ) {
			if ( cTag == 'o' ) {
				RING_API_RETSTRING2(pBody,nLen);
				g_pFree((void *) pOut);
				return ;
			}
			if ( cTag == 'z' ) {
				RING_API_RETNUMBER(0);
				g_pFree((void *) pOut);
				return ;
			}
		}
		if ( nMode == DN_MODE_ANY && cTag == 'o' ) {
			List *pList = RING_API_NEWLIST ;
			ring_list_adddouble(pList,2);
			ring_list_addstring2(pList,pBody,(unsigned int) nLen);
			RING_API_RETLISTBYREF(pList);
			g_pFree((void *) pOut);
			return ;
		}
		if ( nMode == DN_MODE_VALUE || nMode == DN_MODE_ANY ) {
			if ( cTag == 's' ) {
				RING_API_RETSTRING2(pBody,nLen);
				g_pFree((void *) pOut);
				return ;
			}
			if ( (cTag == 'n') && (nLen > 0) && (nLen < (int) sizeof(cNum)) ) {
				memcpy(cNum,pBody,(size_t) nLen);
				cNum[nLen] = 0 ;
				RING_API_RETNUMBER(strtod(cNum,NULL));
				g_pFree((void *) pOut);
				return ;
			}
			if ( cTag == 'b' ) {
				RING_API_RETNUMBER((nLen > 0 && pBody[0] == '1') ? 1 : 0);
				g_pFree((void *) pOut);
				return ;
			}
		}
		if ( cTag == 'e' ) {
			char *pError = (char *) malloc((size_t) nLen + 32);
			if ( pError ) {
				sprintf(pError,"DotNet Error: ");
				memcpy(pError + 14,pBody,(size_t) nLen);
				pError[14 + nLen] = 0 ;
				g_pFree((void *) pOut);
				RING_API_ERROR(pError);
				free(pError);
			} else {
				g_pFree((void *) pOut);
				RING_API_ERROR(RING_OOM);
			}
			return ;
		}
	}
	/* any other answer: the Ring function dnFinish reads it (the list is returned by reference: it was made here) */
	{
		List *pList = RING_API_NEWLIST ;
		ring_list_adddouble(pList,1);
		ring_list_addstring2(pList,(const char *) pOut,(unsigned int) nOutSize);
		RING_API_RETLISTBYREF(pList);
	}
	g_pFree((void *) pOut);
}

static void ringdotnet_docall ( void *pPointer, int nMode, int nArgsList )
{
	int nPara, x, nOutSize = 0, nPacked ;
	double nTarget ;
	DnBuf oRequest ;
	const unsigned char *pOut ;
	nPara = RING_API_PARACOUNT ;
	if ( nArgsList && ((nPara != 4) || (! RING_API_ISLIST(4)) || ring_list_isobject(RING_API_GETLIST(4))) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( (nPara < 3) || (! RING_API_ISSTRING(1)) || ((! RING_API_ISNUMBER(2)) && (! RING_API_ISSTRING(2))) || (! RING_API_ISSTRING(3)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( ! ringdotnet_startruntime(NULL) ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	if ( RING_API_ISSTRING(2) ) {
		/* the name of a type (a static method): its handle comes from the table of this file */
		if ( ! ringdotnet_typehandle(RING_API_GETSTRING(2),(int) RING_API_GETSTRINGSIZE(2),&nTarget) ) {
			RING_API_ERROR("Can't find the .NET type");
			return ;
		}
	} else {
		nTarget = RING_API_GETNUMBER(2) ;
	}
	/* the request: the operation, the target, the name and the arguments */
	dnbuf_init(&oRequest);
	nPacked = dnbuf_add(&oRequest,RING_API_GETSTRING(1),(size_t) RING_API_GETSTRINGSIZE(1)) && dnbuf_handle(&oRequest,nTarget) &&
	          dnbuf_add(&oRequest,RING_API_GETSTRING(3),(size_t) RING_API_GETSTRINGSIZE(3)) ;
	if ( nArgsList ) {
		nPacked = dn_packitems(&oRequest,RING_API_GETLIST(4)) ;
	} else {
		for ( x = 4 ; x <= nPara && nPacked > 0 ; x++ ) {
			nPacked = dn_packparam(&oRequest,pPointer,x) ;
		}
	}
	if ( nPacked == 0 ) {
		dnbuf_free(&oRequest);
		RING_API_ERROR(RING_OOM);
		return ;
	}
	if ( nPacked < 0 ) {
		dnbuf_free(&oRequest);
		RING_API_ERROR("DotNet Error: Unsupported parameter type (use strings, numbers, lists and .NET objects)");
		return ;
	}
	fflush(stdout);
	if ( g_nPending >= DN_FLUSH_AT ) {
		ringdotnet_flushpending();
	}
	{
		void *pOldVM = g_pVM ;
		g_pVM = pPointer ;
		g_nDepth++ ;
		pOut = g_pInvoke((const unsigned char *) oRequest.p,(int) oRequest.nSize,&nOutSize);
		g_nDepth-- ;
		g_pVM = pOldVM ;
	}
	dnbuf_free(&oRequest);
	if ( ! pOut ) {
		RING_API_ERROR("The .NET bridge returned no response");
		return ;
	}
	ringdotnet_answer(pPointer,nMode,pOut,nOutSize);
}

RING_FUNC(ring_dotnet_call)
{
	ringdotnet_docall(pPointer,DN_MODE_VALUE,0);
}

RING_FUNC(ring_dotnet_callv)
{
	ringdotnet_docall(pPointer,DN_MODE_VOID,0);
}

RING_FUNC(ring_dotnet_callo)
{
	ringdotnet_docall(pPointer,DN_MODE_OBJECT,0);
}

RING_FUNC(ring_dotnet_calla)
{
	ringdotnet_docall(pPointer,DN_MODE_ANY,0);
}

/* dotnet_callmethod(cOperation, nHandle or cTypeName, cName, aArguments): like dotnet_calla, with the arguments in one list
   (callMethod and dnStatic: the number of arguments is known when the program runs) */
RING_FUNC(ring_dotnet_callmethod)
{
	ringdotnet_docall(pPointer,DN_MODE_ANY,1);
}

/* ---------------------------------------------------------------- dotnet_getp, dotnet_setp: typed properties
**  dotnet_getp(nHandle, cName)           the value of a property of a number, a yes/no or a text
**  dotnet_setp(nHandle, cName, xValue)   writes it (a number or a text)
**    The bridge looks the property up by its name on the real type of the object and answers the value, or asks for the generic request (status 3: the
**    property is of another kind, the value does not convert, the handle is not valid...): the request is then made here, exactly as dotnet_call and
**    dotnet_callv would make it, so every answer and every error is the one of the generic path.
**      0 a number or a yes/no, 1 a text, 2 a null text (the marker list that dnFinish reads), 3 the generic request, 4 an error of the property */

static void ringdotnet_typederror ( void *pPointer, DnTyped *pResult )
{
	char *pError = (char *) malloc((size_t) pResult->nTextLength + 32);
	if ( pError ) {
		sprintf(pError,"DotNet Error: ");
		memcpy(pError + 14,pResult->pText,(size_t) pResult->nTextLength);
		pError[14 + pResult->nTextLength] = 0 ;
		RING_API_ERROR(pError);
		free(pError);
	} else {
		RING_API_ERROR(RING_OOM);
	}
}

/* The generic request of a typed call: "get", "set" or "call" with the handle, the name and the parameters nFirst to nLast of the Ring function */
static void ringdotnet_typedrequest ( void *pPointer, const char *cOperation, int nMode, int nFirst, int nLast )
{
	int x ;
	DnBuf oRequest ;
	const unsigned char *pOut ;
	int nOutSize = 0, nPacked ;
	void *pOldVM ;
	dnbuf_init(&oRequest);
	nPacked = dnbuf_add(&oRequest,cOperation,strlen(cOperation)) && dnbuf_handle(&oRequest,RING_API_GETNUMBER(1)) &&
	          dnbuf_item(&oRequest,'s',RING_API_GETSTRING(2),(size_t) RING_API_GETSTRINGSIZE(2)) ;
	for ( x = nFirst ; nFirst > 0 && x <= nLast && nPacked > 0 ; x++ ) {
		nPacked = dn_packparam(&oRequest,pPointer,x) ;
	}
	if ( nPacked == 0 ) {
		dnbuf_free(&oRequest);
		RING_API_ERROR(RING_OOM);
		return ;
	}
	if ( nPacked < 0 ) {
		dnbuf_free(&oRequest);
		RING_API_ERROR("DotNet Error: Unsupported parameter type (use strings, numbers, lists and .NET objects)");
		return ;
	}
	pOldVM = g_pVM ;
	g_pVM = pPointer ;
	g_nDepth++ ;
	pOut = g_pInvoke((const unsigned char *) oRequest.p,(int) oRequest.nSize,&nOutSize);
	g_nDepth-- ;
	g_pVM = pOldVM ;
	dnbuf_free(&oRequest);
	if ( ! pOut ) {
		RING_API_ERROR("The .NET bridge returned no response");
		return ;
	}
	ringdotnet_answer(pPointer,nMode,pOut,nOutSize);
}

RING_FUNC(ring_dotnet_getp)
{
	DnTyped oResult ;
	int nStatus ;
	void *pOldVM ;
	if ( (RING_API_PARACOUNT != 2) || (! RING_API_ISNUMBER(1)) || (! RING_API_ISSTRING(2)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( (! g_pGetProp) && (! ringdotnet_startruntime(NULL)) ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	fflush(stdout);
	if ( g_nPending >= DN_FLUSH_AT ) {
		ringdotnet_flushpending();
	}
	pOldVM = g_pVM ;
	g_pVM = pPointer ;
	g_nDepth++ ;
	nStatus = g_pGetProp((int64_t) RING_API_GETNUMBER(1),(const unsigned char *) RING_API_GETSTRING(2),(int32_t) RING_API_GETSTRINGSIZE(2),&oResult) ;
	g_nDepth-- ;
	g_pVM = pOldVM ;
	switch ( nStatus ) {
		case 0 :
			RING_API_RETNUMBER(oResult.nNumber);
			return ;
		case 1 :
			RING_API_RETSTRING2((const char *) oResult.pText,(unsigned int) oResult.nTextLength);
			return ;
		case 2 : {
			List *pList = RING_API_NEWLIST ;
			ring_list_adddouble(pList,1);
			ring_list_addstring2(pList,"z0:",3);
			RING_API_RETLISTBYREF(pList);
			return ;
		}
		case 4 :
			ringdotnet_typederror(pPointer,&oResult);
			return ;
		default :
			ringdotnet_typedrequest(pPointer,"s3:get",DN_MODE_VALUE,0,0);
	}
}

RING_FUNC(ring_dotnet_setp)
{
	DnTyped oResult ;
	int nStatus = 3 ;
	void *pOldVM ;
	if ( (RING_API_PARACOUNT != 3) || (! RING_API_ISNUMBER(1)) || (! RING_API_ISSTRING(2)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( (! g_pSetPropNumber) && (! ringdotnet_startruntime(NULL)) ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	fflush(stdout);
	if ( g_nPending >= DN_FLUSH_AT ) {
		ringdotnet_flushpending();
	}
	pOldVM = g_pVM ;
	g_pVM = pPointer ;
	g_nDepth++ ;
	if ( RING_API_ISNUMBER(3) ) {
		nStatus = g_pSetPropNumber((int64_t) RING_API_GETNUMBER(1),(const unsigned char *) RING_API_GETSTRING(2),(int32_t) RING_API_GETSTRINGSIZE(2),RING_API_GETNUMBER(3),&oResult) ;
	} else if ( RING_API_ISSTRING(3) ) {
		nStatus = g_pSetPropText((int64_t) RING_API_GETNUMBER(1),(const unsigned char *) RING_API_GETSTRING(2),(int32_t) RING_API_GETSTRINGSIZE(2),
		                         (const unsigned char *) RING_API_GETSTRING(3),(int32_t) RING_API_GETSTRINGSIZE(3),&oResult) ;
	}
	g_nDepth-- ;
	g_pVM = pOldVM ;
	if ( nStatus == 0 ) {
		RING_API_RETNUMBER(1);
		return ;
	}
	if ( nStatus == 4 ) {
		ringdotnet_typederror(pPointer,&oResult);
		return ;
	}
	ringdotnet_typedrequest(pPointer,"s3:set",DN_MODE_VOID,3,3);
}

static int dn_listisnamed ( List *pList ) ;

/* dotnet_callt(nHandle, cName, arguments...) and dotnet_calltv(...): a call of a method of numbers, yes/nos and texts, without a request text (see
   Bridge.TypedCalls.cs). dotnet_callt answers a number, a yes/no or a text; dotnet_calltv a method that answers nothing. Status 3 makes the generic
   request, as dotnet_call and dotnet_callv would. */
static void ringdotnet_calltyped ( void *pPointer, int nMode, int nDispatch )
{
	DnTyped oResult ;
	DnTypedArg aArgs[8] ;
	int nPara, nArgs, x, nStatus = 3, nNamed = 0 ;
	void *pOldVM ;
	nPara = RING_API_PARACOUNT ;
	if ( (nPara < 2) || (! RING_API_ISNUMBER(1)) || (! RING_API_ISSTRING(2)) || (nDispatch && (nPara != 3)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( (! g_pCallTyped) && (! ringdotnet_startruntime(NULL)) ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	nArgs = nPara - 2 ;
	if ( nDispatch ) {
		/* the method has overloads: a list of [name, value] pairs chooses the overload by the names of the parameters (the generic request "callnamed"),
		   an empty text (NULL) is a call without arguments, any other value is the one argument */
		if ( RING_API_ISLIST(3) && dn_listisnamed(RING_API_GETLIST(3)) ) {
			nNamed = 1 ;
			nArgs = 9 ;
		} else if ( (nDispatch == 1) && RING_API_ISSTRING(3) && (RING_API_GETSTRINGSIZE(3) == 0) ) {
			nArgs = 0 ;
		}
	}
	if ( nArgs <= 8 ) {
		for ( x = 0 ; x < nArgs ; x++ ) {
			if ( RING_API_ISNUMBER(x + 3) ) {
				aArgs[x].nKind = 1 ;
				aArgs[x].nNumber = RING_API_GETNUMBER(x + 3) ;
				aArgs[x].pText = NULL ;
				aArgs[x].nTextLength = 0 ;
			} else if ( RING_API_ISSTRING(x + 3) ) {
				aArgs[x].nKind = 2 ;
				aArgs[x].nNumber = 0 ;
				aArgs[x].pText = (const unsigned char *) RING_API_GETSTRING(x + 3) ;
				aArgs[x].nTextLength = (int32_t) RING_API_GETSTRINGSIZE(x + 3) ;
			} else {
				break ;
			}
		}
		if ( x == nArgs ) {
			fflush(stdout);
			if ( g_nPending >= DN_FLUSH_AT ) {
				ringdotnet_flushpending();
			}
			pOldVM = g_pVM ;
			g_pVM = pPointer ;
			g_nDepth++ ;
			nStatus = g_pCallTyped((int64_t) RING_API_GETNUMBER(1),(const unsigned char *) RING_API_GETSTRING(2),(int32_t) RING_API_GETSTRINGSIZE(2),aArgs,(int32_t) nArgs,&oResult) ;
			g_nDepth-- ;
			g_pVM = pOldVM ;
		}
	}
	switch ( nStatus ) {
		case 0 :
			if ( nMode == DN_MODE_VOID ) {
				RING_API_RETNUMBER(1);
			} else {
				RING_API_RETNUMBER(oResult.nNumber);
			}
			return ;
		case 1 :
			if ( nMode == DN_MODE_VOID ) {
				RING_API_RETNUMBER(1);
			} else {
				RING_API_RETSTRING2((const char *) oResult.pText,(unsigned int) oResult.nTextLength);
			}
			return ;
		case 2 :
		case 5 : {
			if ( nMode == DN_MODE_VOID ) {
				RING_API_RETNUMBER(1);
			} else {
				List *pList = RING_API_NEWLIST ;
				ring_list_adddouble(pList,1);
				ring_list_addstring2(pList,"z0:",3);
				RING_API_RETLISTBYREF(pList);
			}
			return ;
		}
		case 4 :
			ringdotnet_typederror(pPointer,&oResult);
			return ;
		default :
			if ( nNamed ) {
				ringdotnet_typedrequest(pPointer,"s9:callnamed",nMode,3,3);
			} else if ( (nDispatch == 1) && RING_API_ISSTRING(3) && (RING_API_GETSTRINGSIZE(3) == 0) ) {
				ringdotnet_typedrequest(pPointer,"s4:call",nMode,0,0);
			} else {
				ringdotnet_typedrequest(pPointer,"s4:call",nMode,3,nPara);
			}
	}
}

RING_FUNC(ring_dotnet_callt)
{
	ringdotnet_calltyped(pPointer,DN_MODE_VALUE,0);
}

RING_FUNC(ring_dotnet_calltv)
{
	ringdotnet_calltyped(pPointer,DN_MODE_VOID,0);
}

/* dotnet_calltd(nHandle, cName, P1) and dotnet_calltdv: the method of a name that has overloads (a call with no argument, with one value, or with a list of
   [name, value] pairs): the argument decides, as in the generated dispatcher. dotnet_calltd1 and dotnet_calltd1v: the same for a name that has no overload
   without parameters, so an empty text is the one argument */
RING_FUNC(ring_dotnet_calltd)
{
	ringdotnet_calltyped(pPointer,DN_MODE_VALUE,1);
}

RING_FUNC(ring_dotnet_calltdv)
{
	ringdotnet_calltyped(pPointer,DN_MODE_VOID,1);
}

RING_FUNC(ring_dotnet_calltd1)
{
	ringdotnet_calltyped(pPointer,DN_MODE_VALUE,2);
}

RING_FUNC(ring_dotnet_calltd1v)
{
	ringdotnet_calltyped(pPointer,DN_MODE_VOID,2);
}

/* 1 for a list of [name, value] pairs, the way Ring passes named arguments: [ :server = "x", :port = 80 ]  ([] too); an object is not one */
static int dn_listisnamed ( List *pList )
{
	unsigned int x, nSize ;
	if ( ring_list_isobject(pList) ) {
		return 0 ;
	}
	nSize = ring_list_getsize(pList) ;
	for ( x = 1 ; x <= nSize ; x++ ) {
		List *pItem ;
		if ( ! ring_list_islist(pList,x) ) {
			return 0 ;
		}
		pItem = ring_list_getlist(pList,x) ;
		if ( (ring_list_getsize(pItem) != 2) || (! ring_list_isstring(pItem,1)) ) {
			return 0 ;
		}
	}
	return 1 ;
}

/* dotnet_isnamed(xValue): 1 for a list of [name, value] pairs, the way Ring passes named arguments: [ :server = "x", :port = 80 ]  ([] too) */
RING_FUNC(ring_dotnet_isnamed)
{
	if ( (RING_API_PARACOUNT != 1) || (! RING_API_ISLIST(1)) ) {
		RING_API_RETNUMBER(0);
		return ;
	}
	RING_API_RETNUMBER(dn_listisnamed(RING_API_GETLIST(1)));
}

/* dotnet_callbackrequest() --> the packed request of the running callback (function name, arguments) */
RING_FUNC(ring_dotnet_callbackrequest)
{
	RING_API_RETSTRING2(g_pCallbackRequest ? g_pCallbackRequest : "",g_pCallbackRequest ? g_nCallbackRequestSize : 0);
}

/* dotnet_callbackresult(cPackedResult) */
RING_FUNC(ring_dotnet_callbackresult)
{
	if ( (RING_API_PARACOUNT != 1) || (! RING_API_ISSTRING(1)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	ringdotnet_setresult(RING_API_GETSTRING(1),(int) RING_API_GETSTRINGSIZE(1));
}

/* ---------------------------------------------------------------- dotnet_unpack: the answer of the bridge as a Ring list, read in C
**
**  dotnet_unpack(cItems)       the wire items of cItems as a list: [ item, item, ... ]
**  dotnet_unpacklist(cItem)    cItem is ONE list item ("l...:..."): the list that it holds (no outer list, so Ring does not copy it)
**    Only texts (s), numbers (n), yes/no (b) and lists of them (l) are read here. Any other item (an object, null, an error, a number
**    that is not plain) or any malformed text makes the answer 0, and the Ring function dnUnpack reads the items itself.
*/

#define DN_UNPACK_DEPTH 64

/* Read the items of p[0..nSize) into pList (NULL: only check them). Returns 1 when every item can be read here */
static int dn_unpackitems ( List *pList, const char *p, size_t nSize, int nDepth )
{
	size_t nPos = 0, nLen, nDigits, x ;
	char cTag, cNum[48] ;
	while ( nPos < nSize ) {
		cTag = p[nPos++] ;
		nLen = 0 ;
		nDigits = 0 ;
		while ( (nPos < nSize) && (p[nPos] >= '0') && (p[nPos] <= '9') ) {
			nLen = nLen * 10 + (size_t) (p[nPos] - '0') ;
			nPos++ ;
			nDigits++ ;
			if ( nDigits > 9 ) {
				return 0 ;
			}
		}
		if ( (nDigits == 0) || (nPos >= nSize) || (p[nPos] != ':') ) {
			return 0 ;
		}
		nPos++ ;
		if ( nLen > nSize - nPos ) {
			return 0 ;
		}
		switch ( cTag ) {
			case 's' :
				if ( pList ) {
					ring_list_addstring2(pList,p + nPos,(unsigned int) nLen);
				}
				break ;
			case 'n' :
				/* a plain number only: digits, a sign, a point and an exponent (what number() of Ring reads) */
				if ( (nLen == 0) || (nLen >= sizeof(cNum)) ) {
					return 0 ;
				}
				for ( x = 0 ; x < nLen ; x++ ) {
					char c = p[nPos + x] ;
					if ( ! ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.' || c == 'e' || c == 'E') ) {
						return 0 ;
					}
				}
				if ( pList ) {
					memcpy(cNum,p + nPos,nLen);
					cNum[nLen] = 0 ;
					ring_list_adddouble(pList,strtod(cNum,NULL));
				}
				break ;
			case 'b' :
				if ( pList ) {
					ring_list_adddouble(pList,((nLen > 0) && (p[nPos] == '1')) ? 1 : 0);
				}
				break ;
			case 'l' :
				if ( nDepth >= DN_UNPACK_DEPTH ) {
					return 0 ;
				}
				if ( ! dn_unpackitems(pList ? ring_list_newlist(pList) : NULL,p + nPos,nLen,nDepth + 1) ) {
					return 0 ;
				}
				break ;
			default :
				return 0 ;
		}
		nPos += nLen ;
	}
	return 1 ;
}

RING_FUNC(ring_dotnet_unpack)
{
	List *pList ;
	if ( (RING_API_PARACOUNT != 1) || (! RING_API_ISSTRING(1)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	/* check first, then build: a list that is not used is not made */
	if ( ! dn_unpackitems(NULL,RING_API_GETSTRING(1),(size_t) RING_API_GETSTRINGSIZE(1),0) ) {
		RING_API_RETNUMBER(0);
		return ;
	}
	pList = RING_API_NEWLIST ;
	dn_unpackitems(pList,RING_API_GETSTRING(1),(size_t) RING_API_GETSTRINGSIZE(1),0);
	RING_API_RETLISTBYREF(pList);
}

RING_FUNC(ring_dotnet_unpacklist)
{
	const char *p ;
	size_t nSize, nPos = 1, nLen = 0, nDigits = 0 ;
	List *pList ;
	if ( (RING_API_PARACOUNT != 1) || (! RING_API_ISSTRING(1)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	p = RING_API_GETSTRING(1) ;
	nSize = (size_t) RING_API_GETSTRINGSIZE(1) ;
	/* exactly one list item: l<length>:<items> */
	if ( (nSize < 3) || (p[0] != 'l') ) {
		RING_API_RETNUMBER(0);
		return ;
	}
	while ( (nPos < nSize) && (p[nPos] >= '0') && (p[nPos] <= '9') && (nDigits < 10) ) {
		nLen = nLen * 10 + (size_t) (p[nPos] - '0') ;
		nPos++ ;
		nDigits++ ;
	}
	if ( (nDigits == 0) || (nDigits > 9) || (nPos >= nSize) || (p[nPos] != ':') || (nSize != nPos + 1 + nLen) ) {
		RING_API_RETNUMBER(0);
		return ;
	}
	nPos++ ;
	if ( ! dn_unpackitems(NULL,p + nPos,nLen,1) ) {
		RING_API_RETNUMBER(0);
		return ;
	}
	pList = RING_API_NEWLIST ;
	dn_unpackitems(pList,p + nPos,nLen,1);
	RING_API_RETLISTBYREF(pList);
}

/* dotnet_tolistok(nHandle), dotnet_tolistget(), dotnet_tolistraw(): the items of a collection or an array as a Ring list, in two steps.
   dotnet_tolistok makes the request "tolist" and keeps the answer here: it answers 1 when every item is a text, a number, a yes/no or a list of them, and 0
   otherwise (an object, a null...); an error of .NET is raised. Then dotnet_tolistget makes the Ring list from the kept answer in C and returns it as it is
   (a Ring function that held or passed the list would copy it), and dotnet_tolistraw returns the kept answer as a text, which dnFinish reads (the objects are
   wrapped by Ring), so a collection of objects is not asked twice. */
static unsigned char *g_pListAnswer = NULL ;
static int g_nListAnswerSize = 0 ;

static void ringdotnet_dropanswer ( void )
{
	if ( g_pListAnswer ) {
		g_pFree((void *) g_pListAnswer);
		g_pListAnswer = NULL ;
	}
	g_nListAnswerSize = 0 ;
}

/* the position and the length of the items of an answer that is exactly one list item (l<length>:<items>), or 0 */
static int ringdotnet_listitems ( const unsigned char *p, int nSize, size_t *pPos, size_t *pLen )
{
	size_t nPos = 1, nLen = 0, nDigits = 0 ;
	if ( (nSize < 3) || (p[0] != 'l') ) {
		return 0 ;
	}
	while ( (nPos < (size_t) nSize) && (p[nPos] >= '0') && (p[nPos] <= '9') && (nDigits < 10) ) {
		nLen = nLen * 10 + (size_t) (p[nPos] - '0') ;
		nPos++ ;
		nDigits++ ;
	}
	if ( (nDigits == 0) || (nDigits > 9) || (nPos >= (size_t) nSize) || (p[nPos] != ':') || ((size_t) nSize != nPos + 1 + nLen) ) {
		return 0 ;
	}
	*pPos = nPos + 1 ;
	*pLen = nLen ;
	return 1 ;
}

RING_FUNC(ring_dotnet_tolistok)
{
	DnBuf oRequest ;
	const unsigned char *pOut ;
	int nOutSize = 0, nPacked ;
	void *pOldVM ;
	size_t nPos, nLen ;
	if ( (RING_API_PARACOUNT != 1) || (! RING_API_ISNUMBER(1)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( ! ringdotnet_startruntime(NULL) ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	ringdotnet_dropanswer();
	dnbuf_init(&oRequest);
	nPacked = dnbuf_add(&oRequest,"s6:tolist",9) && dnbuf_handle(&oRequest,RING_API_GETNUMBER(1)) ;
	if ( nPacked == 0 ) {
		dnbuf_free(&oRequest);
		RING_API_ERROR(RING_OOM);
		return ;
	}
	fflush(stdout);
	if ( g_nPending >= DN_FLUSH_AT ) {
		ringdotnet_flushpending();
	}
	pOldVM = g_pVM ;
	g_pVM = pPointer ;
	g_nDepth++ ;
	pOut = g_pInvoke((const unsigned char *) oRequest.p,(int) oRequest.nSize,&nOutSize);
	g_nDepth-- ;
	g_pVM = pOldVM ;
	dnbuf_free(&oRequest);
	if ( ! pOut ) {
		RING_API_ERROR("The .NET bridge returned no response");
		return ;
	}
	if ( (nOutSize > 0) && (pOut[0] == 'e') ) {
		/* an error of .NET: raised here, as the generic request raises it */
		ringdotnet_answer(pPointer,DN_MODE_VALUE,pOut,nOutSize);
		return ;
	}
	g_pListAnswer = (unsigned char *) pOut ;
	g_nListAnswerSize = nOutSize ;
	RING_API_RETNUMBER((ringdotnet_listitems(pOut,nOutSize,&nPos,&nLen) && dn_unpackitems(NULL,(const char *) pOut + nPos,nLen,1)) ? 1 : 0);
}

RING_FUNC(ring_dotnet_tolistget)
{
	size_t nPos, nLen ;
	if ( g_pListAnswer && ringdotnet_listitems(g_pListAnswer,g_nListAnswerSize,&nPos,&nLen) ) {
		List *pList = RING_API_NEWLIST ;
		dn_unpackitems(pList,(const char *) g_pListAnswer + nPos,nLen,1);
		RING_API_RETLISTBYREF(pList);
		ringdotnet_dropanswer();
		return ;
	}
	RING_API_ERROR("DotNet Error: no list was kept");
}

RING_FUNC(ring_dotnet_tolistraw)
{
	if ( g_pListAnswer ) {
		RING_API_RETSTRING2((const char *) g_pListAnswer,g_nListAnswerSize);
		ringdotnet_dropanswer();
		return ;
	}
	RING_API_ERROR("DotNet Error: no list was kept");
}

RING_LIBINIT
{
	RING_API_REGISTER("dotnet_start",ring_dotnet_start);
	RING_API_REGISTER("dotnet_invoke",ring_dotnet_invoke);
	RING_API_REGISTER("dotnet_call",ring_dotnet_call);
	RING_API_REGISTER("dotnet_callv",ring_dotnet_callv);
	RING_API_REGISTER("dotnet_callo",ring_dotnet_callo);
	RING_API_REGISTER("dotnet_calla",ring_dotnet_calla);
	RING_API_REGISTER("dotnet_callmethod",ring_dotnet_callmethod);
	RING_API_REGISTER("dotnet_isnamed",ring_dotnet_isnamed);
	RING_API_REGISTER("dotnet_getp",ring_dotnet_getp);
	RING_API_REGISTER("dotnet_tolistok",ring_dotnet_tolistok);
	RING_API_REGISTER("dotnet_tolistget",ring_dotnet_tolistget);
	RING_API_REGISTER("dotnet_tolistraw",ring_dotnet_tolistraw);
	RING_API_REGISTER("dotnet_setp",ring_dotnet_setp);
	RING_API_REGISTER("dotnet_callt",ring_dotnet_callt);
	RING_API_REGISTER("dotnet_calltv",ring_dotnet_calltv);
	RING_API_REGISTER("dotnet_calltd",ring_dotnet_calltd);
	RING_API_REGISTER("dotnet_calltdv",ring_dotnet_calltdv);
	RING_API_REGISTER("dotnet_calltd1",ring_dotnet_calltd1);
	RING_API_REGISTER("dotnet_calltd1v",ring_dotnet_calltd1v);
	RING_API_REGISTER("dotnet_unpack",ring_dotnet_unpack);
	RING_API_REGISTER("dotnet_unpacklist",ring_dotnet_unpacklist);
	RING_API_REGISTER("dotnet_guard",ring_dotnet_guard);
	RING_API_REGISTER("dotnet_unguard",ring_dotnet_unguard);
	RING_API_REGISTER("dotnet_pending",ring_dotnet_pending);
	RING_API_REGISTER("dotnet_flush",ring_dotnet_flush);
	RING_API_REGISTER("dotnet_info",ring_dotnet_info);
	RING_API_REGISTER("dotnet_callbackrequest",ring_dotnet_callbackrequest);
	RING_API_REGISTER("dotnet_callbackresult",ring_dotnet_callbackresult);
}

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
**  dotnet_call(cOperation, nHandle, cName, arg1, arg2, ...)
**    cOperation and cName are ready wire items ("s4:call", "s8:Contains"), nHandle is the handle of the target (0: the null object) and
**    the arguments are Ring texts and numbers. The request is the same text that dnSend makes in Ring, the answer is read here:
**      a text, a number or a yes/no  --> that value (a .NET error is raised as a Ring error)
**      any other answer (an object, a list, null) --> the list [1, answer], for the Ring function dnFinish
**      an argument that is not a text or a number (an object, a list)         --> the list [0]: nothing was sent, the Ring path is used
*/

/* append one text item "s<length>:<data>" */
static char *ringdotnet_additem ( char *p, char cTag, const char *cData, int nSize )
{
	p += sprintf(p,"%c%d:",cTag,nSize);
	memcpy(p,cData,(size_t) nSize);
	return p + nSize ;
}

static void ringdotnet_docall ( void *pPointer, int nVoid )
{
	int nPara, x, nSize, nOutSize = 0, nLen, nColon ;
	size_t nCapacity ;
	char *pRequest, *p, cNum[48], *pStack ;
	char cLocal[1024] ;
	const unsigned char *pOut ;
	char cTag ;
	nPara = RING_API_PARACOUNT ;
	if ( (nPara < 3) || (! RING_API_ISSTRING(1)) || (! RING_API_ISNUMBER(2)) || (! RING_API_ISSTRING(3)) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	/* the size of the request: the operation, the target, the name and the arguments (a number needs at most 48 bytes) */
	nCapacity = (size_t) RING_API_GETSTRINGSIZE(1) + (size_t) RING_API_GETSTRINGSIZE(3) + 64 ;
	for ( x = 4 ; x <= nPara ; x++ ) {
		if ( RING_API_ISSTRING(x) ) {
			nCapacity += (size_t) RING_API_GETSTRINGSIZE(x) + 24 ;
		} else if ( RING_API_ISNUMBER(x) ) {
			nCapacity += 64 ;
		} else {
			List *pList = RING_API_NEWLIST ;
			ring_list_adddouble(pList,0);
			RING_API_RETLIST(pList);
			return ;
		}
	}
	pStack = NULL ;
	if ( nCapacity <= sizeof(cLocal) ) {
		pRequest = cLocal ;
	} else {
		pStack = (char *) malloc(nCapacity);
		if ( ! pStack ) {
			RING_API_ERROR(RING_OOM);
			return ;
		}
		pRequest = pStack ;
	}
	p = pRequest ;
	memcpy(p,RING_API_GETSTRING(1),(size_t) RING_API_GETSTRINGSIZE(1));
	p += RING_API_GETSTRINGSIZE(1) ;
	if ( RING_API_GETNUMBER(2) == 0 ) {
		p += sprintf(p,"z0:");
	} else {
		nLen = sprintf(cNum,"%.0f",RING_API_GETNUMBER(2));
		p += sprintf(p,"o%d:%s",nLen,cNum);
	}
	memcpy(p,RING_API_GETSTRING(3),(size_t) RING_API_GETSTRINGSIZE(3));
	p += RING_API_GETSTRINGSIZE(3) ;
	for ( x = 4 ; x <= nPara ; x++ ) {
		if ( RING_API_ISSTRING(x) ) {
			p = ringdotnet_additem(p,'s',RING_API_GETSTRING(x),(int) RING_API_GETSTRINGSIZE(x));
		} else {
			double nValue = RING_API_GETNUMBER(x) ;
			if ( (nValue == floor(nValue)) && (fabs(nValue) < 1000000000000.0) ) {
				nLen = sprintf(cNum,"%.0f",nValue);
				p += sprintf(p,"n%d:%s",nLen,cNum);
			} else {
				/* other numbers travel as the 8 bytes of the double (no loss of precision) */
				memcpy(p,"d8:",3);
				memcpy(p + 3,&nValue,8);
				p += 11 ;
			}
		}
	}
	nSize = (int) (p - pRequest) ;
	if ( ! ringdotnet_startruntime(NULL) ) {
		free(pStack);
		RING_API_ERROR(g_cError);
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
		pOut = g_pInvoke((const unsigned char *) pRequest,nSize,&nOutSize);
		g_nDepth-- ;
		g_pVM = pOldVM ;
	}
	free(pStack);
	if ( ! pOut ) {
		RING_API_ERROR("The .NET bridge returned no response");
		return ;
	}
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
		if ( nVoid && (cTag != 'e') ) {
			RING_API_RETNUMBER(1);
			g_pFree((void *) pOut);
			return ;
		}
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
	/* an object, a list, null...: the Ring function dnFinish reads the answer */
	{
		List *pList = RING_API_NEWLIST ;
		ring_list_adddouble(pList,1);
		ring_list_addstring2(pList,(const char *) pOut,(unsigned int) nOutSize);
		RING_API_RETLIST(pList);
	}
	g_pFree((void *) pOut);
}


/* dotnet_call(...) --> the answer (see above); dotnet_callv(...) for a method that returns nothing: 1, or an error */
RING_FUNC(ring_dotnet_call)
{
	ringdotnet_docall(pPointer,0);
}

RING_FUNC(ring_dotnet_callv)
{
	ringdotnet_docall(pPointer,1);
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

RING_LIBINIT
{
	RING_API_REGISTER("dotnet_start",ring_dotnet_start);
	RING_API_REGISTER("dotnet_invoke",ring_dotnet_invoke);
	RING_API_REGISTER("dotnet_call",ring_dotnet_call);
	RING_API_REGISTER("dotnet_callv",ring_dotnet_callv);
	RING_API_REGISTER("dotnet_guard",ring_dotnet_guard);
	RING_API_REGISTER("dotnet_unguard",ring_dotnet_unguard);
	RING_API_REGISTER("dotnet_pending",ring_dotnet_pending);
	RING_API_REGISTER("dotnet_flush",ring_dotnet_flush);
	RING_API_REGISTER("dotnet_info",ring_dotnet_info);
	RING_API_REGISTER("dotnet_callbackrequest",ring_dotnet_callbackrequest);
	RING_API_REGISTER("dotnet_callbackresult",ring_dotnet_callbackresult);
}

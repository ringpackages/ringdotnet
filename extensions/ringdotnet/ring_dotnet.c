/*
**  RingDotNet - .NET Extension for the Ring Programming Language
**  Hosts the .NET runtime (through hostfxr) inside the Ring process and forwards
**  requests to the managed bridge (RingDotNet.Bridge.dll).
**
**  The extension is intentionally thin: it exports three functions
**      dotnet_start()            start the runtime and load the bridge (once)
**      dotnet_invoke(cRequest)   send one request, get one response (binary-safe strings)
**      dotnet_info()             path of the hostfxr library that was used
**  The request/response wire format is described in bridge/Bridge.cs and is
**  packed/unpacked by libraries/dotnetlib (Ring code).
*/

#include "ring.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

static int g_nStarted = 0 ;
static dn_invoke_fn g_pInvoke = NULL ;
static dn_free_fn g_pFree = NULL ;
static char g_cHostFxr[DN_PATHSIZE] = "" ;
static char g_cError[DN_PATHSIZE] = "" ;

static void ringdotnet_seterror ( const char *cMsg, const char *cDetail )
{
	snprintf(g_cError,DN_PATHSIZE,"%s%s%s",cMsg,cDetail ? ": " : "",cDetail ? cDetail : "");
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
	snprintf(cFolder,nSize,"%s",oInfo.dli_fname);
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
	snprintf(cDest,nSize,"%s",cSrc);
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
	snprintf(cDir,DN_PATHSIZE,"%s/host/fxr",cRoot);
#ifdef _WIN32
	{
		WIN32_FIND_DATAA oData ;
		char cPattern[DN_PATHSIZE] ;
		HANDLE hFind ;
		snprintf(cPattern,DN_PATHSIZE,"%s/*",cDir);
		hFind = FindFirstFileA(cPattern,&oData);
		if ( hFind == INVALID_HANDLE_VALUE ) {
			return 0 ;
		}
		do {
			if ( (oData.cFileName[0] >= '0') && (oData.cFileName[0] <= '9') ) {
				if ( (cBest[0] == 0) || (ringdotnet_vercmp(oData.cFileName,cBest) > 0) ) {
					snprintf(cBest,sizeof(cBest),"%s",oData.cFileName);
				}
			}
		} while ( FindNextFileA(hFind,&oData) );
		FindClose(hFind);
	}
	if ( cBest[0] == 0 ) {
		return 0 ;
	}
	snprintf(cOut,nSize,"%s/%s/hostfxr.dll",cDir,cBest);
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
					snprintf(cBest,sizeof(cBest),"%s",pEntry->d_name);
				}
			}
		}
		closedir(pDir);
		if ( cBest[0] == 0 ) {
			return 0 ;
		}
	#ifdef __APPLE__
		snprintf(cOut,nSize,"%s/%s/libhostfxr.dylib",cDir,cBest);
	#else
		snprintf(cOut,nSize,"%s/%s/libhostfxr.so",cDir,cBest);
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
		snprintf(cTemp,DN_PATHSIZE,"%s/dotnet",cRoot);
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

/* Start the runtime and bind the bridge entry points, returns 1 on success */
static int ringdotnet_startruntime ( void )
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
	snprintf(cPath,DN_PATHSIZE,"%s/%s",cFolder,DN_BRIDGE_ASSEMBLY);
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
	snprintf(cPath,DN_PATHSIZE,"%s/%s",cFolder,DN_BRIDGE_CONFIG);
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
	snprintf(cPath,DN_PATHSIZE,"%s/%s",cFolder,DN_BRIDGE_ASSEMBLY);
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
	g_nStarted = 1 ;
	return 1 ;
}

/* dotnet_start() --> 1 */
RING_FUNC(ring_dotnet_start)
{
	if ( RING_API_PARACOUNT != 0 ) {
		RING_API_ERROR(RING_API_BADPARACOUNT);
		return ;
	}
	if ( ! ringdotnet_startruntime() ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	RING_API_RETNUMBER(1);
}

/* dotnet_invoke(cRequest) --> cResponse */
RING_FUNC(ring_dotnet_invoke)
{
	unsigned char *pOut ;
	int nOutSize = 0 ;
	if ( RING_API_PARACOUNT != 1 ) {
		RING_API_ERROR(RING_API_MISS1PARA);
		return ;
	}
	if ( ! RING_API_ISSTRING(1) ) {
		RING_API_ERROR(RING_API_BADPARATYPE);
		return ;
	}
	if ( ! ringdotnet_startruntime() ) {
		RING_API_ERROR(g_cError);
		return ;
	}
	/* Keep the output order between Ring (C stdio) and .NET (Console) */
	fflush(stdout);
	pOut = g_pInvoke((const unsigned char *) RING_API_GETSTRING(1),(int) RING_API_GETSTRINGSIZE(1),&nOutSize);
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

RING_LIBINIT
{
	RING_API_REGISTER("dotnet_start",ring_dotnet_start);
	RING_API_REGISTER("dotnet_invoke",ring_dotnet_invoke);
	RING_API_REGISTER("dotnet_info",ring_dotnet_info);
}

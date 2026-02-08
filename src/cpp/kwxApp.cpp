/*
 * kwxApp - Pure C interface for wxWidgets application startup
 *
 * This is a copy of the reference implementation from kwxFFI examples,
 * adapted for use as part of the kwxJulia library.
 *
 * Original source: kwxFFI/examples/CApp/kwxApp.cpp
 */

#include <wx/cmdline.h>
#include <wx/tooltip.h>
#include <wx/wx.h>

#include <cstdlib>
#include <cstring>

// Export macro for cross-platform compatibility
// SHARED_LIBRARY is defined by kwxFFI's CMakeLists.txt when building as shared DLL.
// KWXJULIA_EXPORTS supports building as a standalone DLL (legacy).
#ifdef _WIN32
#if defined(SHARED_LIBRARY) || defined(KWXJULIA_EXPORTS)
#define KWXAPP_API __declspec(dllexport)
#else
#define KWXAPP_API __declspec(dllimport)
#endif
#else
#define KWXAPP_API __attribute__((visibility("default")))
#endif

/*-----------------------------------------------------------------------------
    Closure/Callback classes for event routing.
    When compiled as part of kwxFFI (via target_sources), these are provided
    by wrapper.h through the precompiled header. When compiled standalone,
    we define local implementations matching the pattern in kwxFFI's wrapper.h.
-----------------------------------------------------------------------------*/
#ifndef SHARED_LIBRARY
// Standalone build: define our own closure/callback classes
typedef void(_cdecl *ClosureFun)(void *_fun, void *_data, void *_evt);

class wxClosure : public wxClientData
{
protected:
    int m_refcount;
    ClosureFun m_fun;
    void *m_data;

public:
    wxClosure(ClosureFun fun, void *data) : m_refcount(0), m_fun(fun), m_data(data) {}
    ~wxClosure() override
    {
        // Signal cleanup to the callback function (evt=nullptr convention)
        if (m_fun)
            m_fun(nullptr, m_data, nullptr);
    }
    void IncRef() { m_refcount++; }
    void DecRef()
    {
        m_refcount--;
        if (m_refcount <= 0)
            delete this;
    }
    void Invoke(wxEvent *event) { m_fun(nullptr, m_data, event); }
    void *GetData() { return m_data; }
};

class wxCallback : public wxObject
{
private:
    wxClosure *m_closure;

public:
    wxCallback(wxClosure *closure) : m_closure(closure) { m_closure->IncRef(); }
    ~wxCallback() { m_closure->DecRef(); }
    void Invoke(wxEvent *event) { m_closure->Invoke(event); }
    wxClosure *GetClosure() { return m_closure; }
};
#endif // !SHARED_LIBRARY

/*-----------------------------------------------------------------------------
    Internal state
-----------------------------------------------------------------------------*/
namespace
{
    bool g_initialized = false;
    bool g_terminating = false;

    // Idle timer support
    typedef void (*kwxApp_IdleCallback)(void *data);
    kwxApp_IdleCallback g_idleCallback = nullptr;
    void *g_idleCallbackData = nullptr;

    // Cached strings for Get functions (to avoid returning dangling pointers)
    wxString g_cachedAppName;
    wxString g_cachedVendorName;

    // Helper to convert wxString to C string (caller must free)
    char *wxStringToNewCStr(const wxString &str)
    {
        const char *utf8 = str.utf8_str();
        size_t len = strlen(utf8) + 1;
        char *result = static_cast<char *>(malloc(len));
        if (result)
        {
            memcpy(result, utf8, len);
        }
        return result;
    }
} // namespace

/*-----------------------------------------------------------------------------
    Idle Timer Class
-----------------------------------------------------------------------------*/
class kwxIdleTimer : public wxTimer
{
public:
    void Notify() override
    {
        if (g_idleCallback)
        {
            g_idleCallback(g_idleCallbackData);
        }
    }
};

static kwxIdleTimer *g_idleTimer = nullptr;

/*-----------------------------------------------------------------------------
    The wxApp subclass (hidden from C callers)
-----------------------------------------------------------------------------*/
class kwxAppImpl : public wxApp
{
public:
    bool OnInit() override
    {
        if (!wxApp::OnInit())
        {
            return false;
        }
        g_idleTimer = new kwxIdleTimer();
        return true;
    }

    int OnExit() override
    {
        g_terminating = true;
        if (g_idleTimer)
        {
            g_idleTimer->Stop();
            delete g_idleTimer;
            g_idleTimer = nullptr;
        }
        return wxApp::OnExit();
    }

    // Routes events through the closure/callback system to foreign functions
    void HandleEvent(wxEvent &evt);

    // Prevent wxApp from failing on foreign language command line args
    void OnInitCmdLine(wxCmdLineParser &parser) override { parser.SetCmdLine(""); }

    bool OnCmdLineParsed(wxCmdLineParser &) override { return true; }
};

void kwxAppImpl::HandleEvent(wxEvent &evt)
{
    wxCallback *callback = (wxCallback *)(evt.m_callbackUserData);
    if (callback)
    {
        callback->Invoke(&evt);
    }
}

// This is the actual wxApp instance
wxIMPLEMENT_APP_NO_MAIN(kwxAppImpl);

/*-----------------------------------------------------------------------------
    C Interface Implementation
-----------------------------------------------------------------------------*/
extern "C"
{
    KWXAPP_API int kwxApp_Initialize(int argc, char **argv)
    {
        if (g_initialized)
        {
            return 1; // Already initialized
        }

        // wxWidgets requires valid argc/argv
        static char *dummy_argv[] = {const_cast<char *>("kwxApp"), nullptr};
        if (argc <= 0 || argv == nullptr)
        {
            argc = 1;
            argv = dummy_argv;
        }

        if (!wxEntryStart(argc, argv))
        {
            return 0;
        }

        if (!wxTheApp || !wxTheApp->CallOnInit())
        {
            wxEntryCleanup();
            return 0;
        }

        g_initialized = true;
        return 1;
    }

    KWXAPP_API int kwxApp_MainLoop()
    {
        if (!g_initialized || !wxTheApp)
        {
            return -1;
        }
        return wxTheApp->OnRun();
    }

    KWXAPP_API void kwxApp_ExitMainLoop()
    {
        if (wxTheApp)
        {
            wxTheApp->ExitMainLoop();
        }
    }

    KWXAPP_API void kwxApp_Shutdown()
    {
        if (g_initialized)
        {
            g_terminating = true;
            if (wxTheApp)
            {
                wxTheApp->OnExit();
            }
            wxEntryCleanup();
            g_initialized = false;
        }
    }

    KWXAPP_API int kwxApp_IsTerminating()
    {
        return g_terminating ? 1 : 0;
    }

    /*-------------------------------------------------------------------------
        Application Properties
    -------------------------------------------------------------------------*/
    KWXAPP_API const char *kwxApp_GetAppName()
    {
        if (!wxTheApp)
            return "";
        g_cachedAppName = wxTheApp->GetAppName();
        return g_cachedAppName.utf8_str();
    }

    KWXAPP_API void kwxApp_SetAppName(const char *name)
    {
        if (wxTheApp && name)
        {
            wxTheApp->SetAppName(wxString::FromUTF8(name));
        }
    }

    KWXAPP_API const char *kwxApp_GetVendorName()
    {
        if (!wxTheApp)
            return "";
        g_cachedVendorName = wxTheApp->GetVendorName();
        return g_cachedVendorName.utf8_str();
    }

    KWXAPP_API void kwxApp_SetVendorName(const char *name)
    {
        if (wxTheApp && name)
        {
            wxTheApp->SetVendorName(wxString::FromUTF8(name));
        }
    }

    KWXAPP_API void *kwxApp_GetTopWindow()
    {
        return wxTheApp ? wxTheApp->GetTopWindow() : nullptr;
    }

    KWXAPP_API void kwxApp_SetTopWindow(void *window)
    {
        if (wxTheApp)
        {
            wxTheApp->SetTopWindow(static_cast<wxWindow *>(window));
        }
    }

    KWXAPP_API void kwxApp_SetExitOnFrameDelete(int flag)
    {
        if (wxTheApp)
        {
            wxTheApp->SetExitOnFrameDelete(flag != 0);
        }
    }

    KWXAPP_API int kwxApp_GetExitOnFrameDelete()
    {
        return (wxTheApp && wxTheApp->GetExitOnFrameDelete()) ? 1 : 0;
    }

    /*-------------------------------------------------------------------------
        System Information
    -------------------------------------------------------------------------*/
    KWXAPP_API void kwxApp_GetDisplaySize(int *width, int *height)
    {
        wxSize size = wxGetDisplaySize();
        if (width)
            *width = size.GetWidth();
        if (height)
            *height = size.GetHeight();
    }

    KWXAPP_API void kwxApp_GetMousePosition(int *x, int *y)
    {
        wxPoint pos = wxGetMousePosition();
        if (x)
            *x = pos.x;
        if (y)
            *y = pos.y;
    }

    KWXAPP_API int kwxApp_GetOsVersion(int *major, int *minor)
    {
        return wxGetOsVersion(major, minor);
    }

    KWXAPP_API char *kwxApp_GetOsDescription()
    {
        return wxStringToNewCStr(wxGetOsDescription());
    }

    KWXAPP_API char *kwxApp_GetUserId()
    {
        return wxStringToNewCStr(wxGetUserId());
    }

    KWXAPP_API char *kwxApp_GetUserName()
    {
        return wxStringToNewCStr(wxGetUserName());
    }

    /*-------------------------------------------------------------------------
        Event Processing
    -------------------------------------------------------------------------*/
    KWXAPP_API int kwxApp_Pending()
    {
        return (wxTheApp && wxTheApp->Pending()) ? 1 : 0;
    }

    KWXAPP_API void kwxApp_Dispatch()
    {
        if (wxTheApp)
        {
            wxTheApp->Dispatch();
        }
    }

    KWXAPP_API int kwxApp_Yield()
    {
        return wxYield() ? 1 : 0;
    }

    KWXAPP_API int kwxApp_SafeYield(void *window)
    {
        return wxSafeYield(static_cast<wxWindow *>(window)) ? 1 : 0;
    }

    /*-------------------------------------------------------------------------
        Idle Timer
    -------------------------------------------------------------------------*/
#define KWXAPP_MIN_IDLE_INTERVAL_MS 100

    KWXAPP_API void kwxApp_SetIdleCallback(int interval_ms, void (*callback_func)(void *),
                                           void *callback_data)
    {
        g_idleCallback = callback_func;
        g_idleCallbackData = callback_data;

        if (g_idleTimer)
        {
            if (g_idleTimer->IsRunning())
            {
                g_idleTimer->Stop();
            }

            if (callback_func && interval_ms >= KWXAPP_MIN_IDLE_INTERVAL_MS)
            {
                g_idleTimer->Start(interval_ms, false);
            }
        }
    }

    KWXAPP_API int kwxApp_GetIdleInterval()
    {
        if (g_idleTimer && g_idleTimer->IsRunning())
        {
            return g_idleTimer->GetInterval();
        }
        return 0;
    }

    /*-------------------------------------------------------------------------
        Utilities
    -------------------------------------------------------------------------*/
    KWXAPP_API void kwxApp_InitAllImageHandlers()
    {
        wxInitAllImageHandlers();
    }

    KWXAPP_API void kwxApp_EnableTooltips(int enable)
    {
        wxToolTip::Enable(enable != 0);
    }

    KWXAPP_API void kwxApp_SetTooltipDelay(int milliseconds)
    {
        wxToolTip::SetDelay(milliseconds);
    }

    KWXAPP_API void kwxApp_Bell()
    {
        wxBell();
    }

    KWXAPP_API void kwxApp_Sleep(int seconds)
    {
        wxSleep(seconds);
    }

    KWXAPP_API void kwxApp_MilliSleep(int milliseconds)
    {
        wxMilliSleep(milliseconds);
    }

    KWXAPP_API void *kwxApp_FindWindowById(int id, void *parent)
    {
        return wxWindow::FindWindowById(static_cast<long>(id), static_cast<wxWindow *>(parent));
    }

    KWXAPP_API void *kwxApp_FindWindowByLabel(const char *label, void *parent)
    {
        if (!label)
            return nullptr;
        return wxFindWindowByLabel(wxString::FromUTF8(label), static_cast<wxWindow *>(parent));
    }

    KWXAPP_API void *kwxApp_FindWindowByName(const char *name, void *parent)
    {
        if (!name)
            return nullptr;
        return wxFindWindowByName(wxString::FromUTF8(name), static_cast<wxWindow *>(parent));
    }

    KWXAPP_API void kwxApp_FreeString(char *str)
    {
        free(str);
    }

    /*-------------------------------------------------------------------------
        Event Handler Connection
        Uses kwxAppImpl::HandleEvent to route wxWidgets events to closures.
        This follows the same pattern as SampleApp in kwxFFI examples.

        kwxApp_Connect accepts a ClosureFun and user data pointer directly.
        The Julia side does NOT need to call wxClosure_Create — we handle
        closure/callback creation internally.
    -------------------------------------------------------------------------*/

    KWXAPP_API int kwxApp_Connect(void *obj, int first, int last, int type,
                                  ClosureFun fun, void *data)
    {
        auto *closure = new wxClosure(fun, data);
        auto *callback = new wxCallback(closure);
        ((wxEvtHandler *)obj)
            ->Connect(first, last, type,
                      (wxObjectEventFunction)&kwxAppImpl::HandleEvent,
                      callback);
        return 0;
    }

    KWXAPP_API int kwxApp_Disconnect(void *obj, int first, int last, int type)
    {
        return (int)((wxEvtHandler *)obj)
            ->Disconnect(first, last, type,
                         (wxObjectEventFunction)&kwxAppImpl::HandleEvent);
    }

} // extern "C"

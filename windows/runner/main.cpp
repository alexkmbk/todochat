#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
//#include <string>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  /*LPWSTR *szArgList;
  int argCount;

  szArgList = CommandLineToArgvW(GetCommandLine(), &argCount);
  
  if (argCount > 1) {
	  std::wstring link = szArgList[argCount - 1];
	  if (link.substr(0, 8) == L"todochat") {
		  MessageBox(NULL, link.c_str(), L"Arglist contents", MB_OK);
	  }
	  //MessageBox(NULL, szArgList[argCount - 1], L"Arglist contents", MB_OK);
  }

  LocalFree(szArgList);*/


  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.CreateAndShow(L"todochat", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

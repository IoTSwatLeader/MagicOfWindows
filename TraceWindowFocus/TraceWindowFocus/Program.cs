using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace TraceWindowFocus
{
    internal class Program
    {
        [Flags]
        public enum ProcessAccessFlags : uint
        {
            All = 0x001F0FFF,
            Terminate = 0x00000001,
            CreateThread = 0x00000002,
            VirtualMemoryOperation = 0x00000008,
            VirtualMemoryRead = 0x00000010,
            VirtualMemoryWrite = 0x00000020,
            DuplicateHandle = 0x00000040,
            CreateProcess = 0x000000080,
            SetQuota = 0x00000100,
            SetInformation = 0x00000200,
            QueryInformation = 0x00000400,
            QueryLimitedInformation = 0x00001000,
            Synchronize = 0x00100000
        }

        [Flags]
        public enum MemoryProtection
        {
            Execute = 0x10,
            ExecuteRead = 0x20,
            ExecuteReadWrite = 0x40,
            ExecuteWriteCopy = 0x80,
            NoAccess = 0x01,
            ReadOnly = 0x02,
            ReadWrite = 0x04,
            WriteCopy = 0x08,
            GuardModifierflag = 0x100,
            NoCacheModifierflag = 0x200,
            WriteCombineModifierflag = 0x400
        }


        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(
        ProcessAccessFlags processAccess, bool bInheritHandle, int processId);

        [DllImport("kernel32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool CloseHandle(IntPtr hObject);

        [DllImport("psapi.dll")]
        static extern uint GetModuleFileNameEx(IntPtr hProcess, IntPtr hModule, [Out] StringBuilder lpBaseName, [In][MarshalAs(UnmanagedType.U4)] int nSize);

        [DllImport("user32.dll")]
        static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);

        [DllImport("user32.dll")]
        static extern int GetWindowThreadProcessId(IntPtr handle, out int processId);

        [DllImport("psapi.dll")]
        static extern uint GetProcessImageFileName(IntPtr hProcess, [Out] StringBuilder lpImageFileName, [In][MarshalAs(UnmanagedType.U4)] int nSize);

        const int nChars = 1024;

        static void Main(string[] args)
        {
            //set the thread priority of the current thread
            Thread.CurrentThread.Priority = ThreadPriority.AboveNormal;

            //loop the application until closure
            do
            {
                //get the current Foreground Window
                IntPtr handleForegroundWindow = GetForegroundWindow();

                //get the name of the Foreground Window
                const int nChars = 256;
                StringBuilder sbWindowTitle = new StringBuilder(nChars);
                if (GetWindowText(handleForegroundWindow, sbWindowTitle, nChars) > 0)
                {
                    sbWindowTitle.ToString();
                }

                //get the window thread / process ID
                int iProcessId;
                int iThreadId = GetWindowThreadProcessId(handleForegroundWindow, out iProcessId);

                //get the process information
                StringBuilder filename = new StringBuilder(nChars);
                IntPtr ipProcess = OpenProcess(ProcessAccessFlags.QueryLimitedInformation, false, iProcessId);
                if (ipProcess != IntPtr.Zero)
                {
                    GetModuleFileNameEx(ipProcess, IntPtr.Zero, filename, nChars);
                    CloseHandle(ipProcess);
                }

                //output of the run
                Console.WriteLine("{0:MM/dd/yy H:mm:ss zzz }", DateTime.Now);

                Console.WriteLine("\t\tHWND={0}", handleForegroundWindow.ToString());
                Console.WriteLine("\t\tProcID={0}", iProcessId);
                Console.WriteLine("\t\tThreadID={0}", iThreadId);
                Console.WriteLine("\t\tProcess='{0}'", filename);
                Console.WriteLine("\t\tTitle='{0}'", sbWindowTitle.ToString());

                //Sleep for 1 sec
                Thread.Sleep(1000);
            } while (true);
        }

    }
}

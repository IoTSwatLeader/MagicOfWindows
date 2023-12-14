using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace GetWindowsEdition
{
    internal class Program
    {
        //https://learn.microsoft.com/de-de/windows/win32/api/sysinfoapi/nf-sysinfoapi-getproductinfo
        [DllImport("Kernel32.dll")]
        internal static extern bool GetProductInfo(
            int osMajorVersion,
            int osMinorVersion,
            int spMajorVersion,
            int spMinorVersion,
            out int edition);

        // https://learn.microsoft.com/de-de/windows/win32/api/sysinfoapi/nf-sysinfoapi-getproductinfo
        enum ProductEditions
        {
            PRODUCT_BUSINESS = 0x6,
            PRODUCT_BUSINESS_N = 0x10,
            PRODUCT_CLUSTER_SERVER = 0x12,
            PRODUCT_CLUSTER_SERVER_V = 0x40,
            PRODUCT_CORE = 0x65,
            PRODUCT_CORE_COUNTRYSPECIFIC = 0x63,
            PRODUCT_CORE_N = 0x62,
            PRODUCT_CORE_SINGLELANGUAGE = 0x64,
            PRODUCT_DATACENTER_EVALUATION_SERVER = 0x50,
            PRODUCT_DATACENTER_A_SERVER_CORE = 0x91,
            PRODUCT_STANDARD_A_SERVER_CORE = 0x92,
            PRODUCT_DATACENTER_SERVER = 0x8,
            PRODUCT_DATACENTER_SERVER_CORE = 0xC,
            PRODUCT_DATACENTER_SERVER_CORE_V = 0x27,
            PRODUCT_DATACENTER_SERVER_V = 0x25,
            PRODUCT_EDUCATION = 0x79,
            PRODUCT_EDUCATION_N = 0x7A,
            PRODUCT_ENTERPRISE = 0x4,
            PRODUCT_ENTERPRISE_E = 0x46,
            PRODUCT_ENTERPRISE_EVALUATION = 0x48,
            PRODUCT_ENTERPRISE_N = 0x1B,
            PRODUCT_ENTERPRISE_N_EVALUATION = 0x54,
            PRODUCT_ENTERPRISE_S = 0x7D,
            PRODUCT_ENTERPRISE_S_EVALUATION = 0x81,
            PRODUCT_ENTERPRISE_S_N = 0x7E,
            PRODUCT_ENTERPRISE_S_N_EVALUATION = 0x82,
            PRODUCT_ENTERPRISE_SERVER = 0xA,
            PRODUCT_ENTERPRISE_SERVER_CORE = 0xE,
            PRODUCT_ENTERPRISE_SERVER_CORE_V = 0x29,
            PRODUCT_ENTERPRISE_SERVER_IA64 = 0xF,
            PRODUCT_ENTERPRISE_SERVER_V = 0x26,
            PRODUCT_ESSENTIALBUSINESS_SERVER_ADDL = 0x3C,
            PRODUCT_ESSENTIALBUSINESS_SERVER_ADDLSVC = 0x3E,
            PRODUCT_ESSENTIALBUSINESS_SERVER_MGMT = 0x3B,
            PRODUCT_ESSENTIALBUSINESS_SERVER_MGMTSVC = 0x3D,
            PRODUCT_HOME_BASIC = 0x2,
            PRODUCT_HOME_BASIC_E = 0x43,
            PRODUCT_HOME_BASIC_N = 0x5,
            PRODUCT_HOME_PREMIUM = 0x3,
            PRODUCT_HOME_PREMIUM_E = 0x44,
            PRODUCT_HOME_PREMIUM_N = 0x1A,
            PRODUCT_HOME_PREMIUM_SERVER = 0x22,
            PRODUCT_HOME_SERVER = 0x13,
            PRODUCT_HYPERV = 0x2A,
            PRODUCT_IOTENTERPRISE = 0xBC,
            PRODUCT_IOTENTERPRISE_S = 0xBF,
            PRODUCT_IOTUAP = 0x7B,
            PRODUCT_IOTUAPCOMMERCIAL = 0x83,
            PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT = 0x1E,
            PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING = 0x20,
            PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY = 0x1F,
            PRODUCT_MOBILE_CORE = 0x68,
            PRODUCT_MOBILE_ENTERPRISE = 0x85,
            PRODUCT_MULTIPOINT_PREMIUM_SERVER = 0x4D,
            PRODUCT_MULTIPOINT_STANDARD_SERVER = 0x4C,
            PRODUCT_PPI_PRO = 0x77,
            PRODUCT_PRO_FOR_EDUCATION = 0xA4,
            PRODUCT_PRO_WORKSTATION = 0xA1,
            PRODUCT_PRO_WORKSTATION_N = 0xA2,
            PRODUCT_PROFESSIONAL = 0x30,
            PRODUCT_PROFESSIONAL_E = 0x45,
            PRODUCT_PROFESSIONAL_N = 0x31,
            PRODUCT_PROFESSIONAL_WMC = 0x67,
            PRODUCT_SB_SOLUTION_SERVER = 0x32,
            PRODUCT_SB_SOLUTION_SERVER_EM = 0x36,
            PRODUCT_SERVER_FOR_SB_SOLUTIONS = 0x33,
            PRODUCT_SERVER_FOR_SB_SOLUTIONS_EM = 0x37,
            PRODUCT_SERVER_FOR_SMALLBUSINESS = 0x18,
            PRODUCT_SERVER_FOR_SMALLBUSINESS_V = 0x23,
            PRODUCT_SERVER_FOUNDATION = 0x21,
            PRODUCT_SERVERRDSH = 0xAF,
            PRODUCT_SMALLBUSINESS_SERVER = 0x9,
            PRODUCT_SMALLBUSINESS_SERVER_PREMIUM = 0x19,
            PRODUCT_SMALLBUSINESS_SERVER_PREMIUM_CORE = 0x3F,
            PRODUCT_SOLUTION_EMBEDDEDSERVER = 0x38,
            PRODUCT_STANDARD_EVALUATION_SERVER = 0x4F,
            PRODUCT_STANDARD_SERVER = 0x7,
            PRODUCT_STANDARD_SERVER_CORE = 0xD,
            PRODUCT_STANDARD_SERVER_CORE_V = 0x28,
            PRODUCT_STANDARD_SERVER_V = 0x24,
            PRODUCT_STANDARD_SERVER_SOLUTIONS = 0x34,
            PRODUCT_STANDARD_SERVER_SOLUTIONS_CORE = 0x35,
            PRODUCT_STARTER = 0xB,
            PRODUCT_STARTER_E = 0x42,
            PRODUCT_STARTER_N = 0x2F,
            PRODUCT_STORAGE_ENTERPRISE_SERVER = 0x17,
            PRODUCT_STORAGE_ENTERPRISE_SERVER_CORE = 0x2E,
            PRODUCT_STORAGE_EXPRESS_SERVER = 0x14,
            PRODUCT_STORAGE_EXPRESS_SERVER_CORE = 0x2B,
            PRODUCT_STORAGE_STANDARD_EVALUATION_SERVER = 0x60,
            PRODUCT_STORAGE_STANDARD_SERVER = 0x15,
            PRODUCT_STORAGE_STANDARD_SERVER_CORE = 0x2C,
            PRODUCT_STORAGE_WORKGROUP_EVALUATION_SERVER = 0x5F,
            PRODUCT_STORAGE_WORKGROUP_SERVER = 0x16,
            PRODUCT_STORAGE_WORKGROUP_SERVER_CORE = 0x2D,
            PRODUCT_ULTIMATE = 0x1,
            PRODUCT_ULTIMATE_E = 0x47,
            PRODUCT_ULTIMATE_N = 0x1C,
            PRODUCT_UNDEFINED = 0x0,
            PRODUCT_WEB_SERVER = 0x11,
            PRODUCT_WEB_SERVER_CORE = 0x1D
        }

        static void Main(string[] args)
        {
            int ed;
            if (GetProductInfo(Environment.OSVersion.Version.Major
                                , Environment.OSVersion.Version.Minor
                                , 0
                                , 0
                                , out ed))
            {
                Console.WriteLine("Windows Edition: {0} [{1}]", ed.ToString(), Enum.Parse(typeof(ProductEditions), ed.ToString())); 
            }
        }
    }
}

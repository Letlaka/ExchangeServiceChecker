**Script Name: ExchangeServiceChecker.ps1**

# Exchange Service Checker

The **ExchangeServiceChecker.ps1** script is a PowerShell script that helps administrators check the status of Exchange-related services on multiple servers remotely. It also attempts to start any services that are not running and provides a summary of the results and encountered errors.

## Prerequisites

- PowerShell version 5.1 or later.
- Admin credentials with sufficient privileges to access and manage services on the target servers.

## How to Use

1. Clone or download this repository to your local machine.

2. Open PowerShell in the directory where the script is located.

3. Run the script using the following command:

   ```powershell
   .\ExchangeServiceChecker.ps1
   ```

4. The script will prompt you to enter your admin credentials. This is necessary to access the remote servers and interact with services.

5. The script will then check the status of Exchange-related services on each server specified in the `$Servers` array. If any services are not running, it will attempt to start them.

6. After processing all servers, the script will display a summary of services that were not running and have been started, if applicable.

7. If there were any errors encountered during the script execution, the script will display a summary of the errors.

## Configuration

Edit the `$Servers` array in the script to specify the names of the Exchange servers you want to check.

## Notes

- Please ensure that you have the necessary permissions and network connectivity to access the target servers remotely.

- The script uses the `Test-Connection` cmdlet to check if each server is online before attempting to interact with it.

- If any errors occur during the script execution, they will be recorded in the `$ErrorList` array and displayed at the end of the execution.

## Disclaimer

This script is provided as-is without any warranty. Use it at your own risk. The script author is not responsible for any damages or losses caused by using this script.

**Author: Letlaka**
**Contact: Letlaka.t@gmail.com**

Please feel free to contribute to the script by creating pull requests or reporting issues. Your feedback and contributions are highly appreciated!

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

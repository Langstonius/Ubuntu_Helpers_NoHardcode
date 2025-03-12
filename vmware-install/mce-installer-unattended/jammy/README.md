# Ubuntu 22.04 (Jammy) Support for LinuxMCE

This directory contains Ubuntu 22.04 (jammy) specific setup scripts for LinuxMCE.

## Changes Made

1. Added configuration files for amd64, i386, and armhf architectures:
   - `conf-files/jammy-amd64/`
   - `conf-files/jammy-i386/`
   - `conf-files/jammy-armhf/`

2. Updated package dependencies to be compatible with Ubuntu 22.04

3. Created Ubuntu 22.04 specific installer scripts in:
   - `vmware-install/mce-installer-unattended/jammy/`

4. Modified the main installer to detect Ubuntu 22.04 and run the appropriate setup script

## Ubuntu 22.04 Specific Considerations

- Uses systemd-resolved and systemd-networkd for network management
- Python 3 is the default
- Updated package dependencies
- Modified AppArmor configurations for LinuxMCE
- Networking stack changes since older Ubuntu versions

## Testing

After installing, verify that:

1. Networking is properly configured
2. LinuxMCE core services start correctly
3. Media Director functionality works
4. UI elements display properly

## Known Issues

- None currently documented

## Future Improvements

- Add support for Ubuntu 22.04 ARM64 architecture
- Optimize package dependencies further
- Improve integration with systemd

## Contact

For issues or suggestions related to Ubuntu 22.04 support, please report them to the LinuxMCE project.
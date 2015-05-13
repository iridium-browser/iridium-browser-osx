# Build iridium-browser for Mac OS X

## Build steps

### Regular build

Create a folder:

    mkdir Iridium_OSX && cd Iridium_OSX

Clone this repository inside:

    git clone https://github.com/strukturag/iridium-browser-osx.git

Check signing scripts in Iridium_OSX/iridium-browser-osx/code_signing
if you have correctly setup signing identities on your machine.

Setup your signing identities information in `build.config`.

If you do not setup your signing identities in `build.config`, `build.sh` script will automatically search for
signing identities in your default keychain and take the first identity which satisfies search criteria.

Run the script `build.sh -m <mas/iad/nosign>`

    cd iridium-browser-osx
    # for outside of Mac App Store build
    ./build.sh -m iad

    # for explanation of modes and usage run
    # ./build.sh -h

This will also perform a checkout of the source code and start the
compilation. The resulting application will be located in the folder
`Iridium_OSX/iridium-browser-osx/out_ir/<mas/iad/nosign>`.

You can also run scripts separately but you should get familiar with them beforehand.
Scripts of interest relatively to Iridium_OSX/iridium-browser-osx/:

    - build.sh - genereal build script for everything
    - iridium-osx-patch.sh - sources patch script
    - create_dmg.sh - create dmg icon script
    - code_signing/mas_sign.sh - code signing and packaging script for Mac App Store
    - code_signing/sign.sh - code signing script for outside of Mac App Store as Apple Identified Developer

Additional information about building can be found in iridium-browser_build_for_osx.txt.

If you are building on another machine ssh-ing to it please read iridium-browser-osx_build-info.txt first.
If you do not setup your keychain correctly signing will fail.


### Vagrant

Additionally you can now use Vagrantfile shipped with the repo. Tested with VirtualBox as a provider.

You will need your own(because of OSX licensing) OSX vagrant box with Xcode (min 60 GB free space after OS installation).

Information related to how to make your Vagrant base box is here:

* https://docs.vagrantup.com/v2/virtualbox/boxes.html

* http://www.skoblenick.com/vagrant/vmware-fusion/creating-an-osx-base-box/

* https://github.com/AndrewDryga/vagrant-box-osx


Provisioning scripts in Vagrantfile assume:

    - signing identities contain both certificate and private key
    - signing identities are exported in .p12 format
    - passphrase for importing identities is 'vagrant'
    - Vagrant box has standard configuration: insecure SSH key, default 'vagrant' user, passwordless sudo

Build steps:

    1. Clone this repo
    2. Find Vagrantfile in /path/to/repo/vagrant/.
    3. Copy the Vagrantfile and copy_results.sh to the directory of your choice
    4. Copy signing/packaging identities into the parent folder of Vagrantfile
    5. Set the base box name in Vagrantfile to your base box
    6. Set <mas, iad, nosign> parameter for build.sh in step 5 (building) provision sctipts. By default it is 'mas'
    7. Run 'vagrant up'.
    8. Run copy_result.sh. This should copy results of the build into the current directory on host machine

For more information check Vagrantfile.

### LICENSE

GPLv2, please see `LICENSE` file.

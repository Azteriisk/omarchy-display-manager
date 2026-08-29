# Maintainer: Azteriisk <https://github.com/Azteriisk>
pkgname=omarchy-plugin-display-manager-git
pkgver=1.0.0.r0.ga6f51e9
pkgrel=1
pkgdesc="Interactive visual display manager & drag-and-drop monitor positioning extension for Omarchy Linux"
arch=('any')
url="https://github.com/Azteriisk/omarchy-display-manager"
license=('MIT')
depends=('hyprland' 'quickshell')
makedepends=('git')
provides=('omarchy-plugin-display-manager')
conflicts=('omarchy-plugin-display-manager')
source=("git+https://github.com/Azteriisk/omarchy-display-manager.git")
md5sums=('SKIP')

pkgver() {
  cd "$srcdir/omarchy-display-manager"
  git describe --long --tags 2>/dev/null | sed 's/\([^-]*-g\)/r\1/;s/-/./g' ||
  printf "1.0.0.r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd "$srcdir/omarchy-display-manager"

  install -d "$pkgdir/usr/share/omarchy/plugins/azterisk.display-manager"
  install -Dm644 manifest.json "$pkgdir/usr/share/omarchy/plugins/azterisk.display-manager/manifest.json"
  install -Dm644 Panel.qml "$pkgdir/usr/share/omarchy/plugins/azterisk.display-manager/Panel.qml"
  install -Dm644 Model.js "$pkgdir/usr/share/omarchy/plugins/azterisk.display-manager/Model.js"
  install -Dm644 README.md "$pkgdir/usr/share/omarchy/plugins/azterisk.display-manager/README.md"
  install -Dm755 install.sh "$pkgdir/usr/share/omarchy/plugins/azterisk.display-manager/install.sh"
  install -Dm755 uninstall.sh "$pkgdir/usr/share/omarchy/plugins/azterisk.display-manager/uninstall.sh"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

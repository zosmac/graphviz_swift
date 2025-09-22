BUILD_DIR=../build
APP_NAME=GraphvizSwift
APP_DIR=$(APP_NAME).app/Contents/Frameworks
#FRAMEWORKS_DIR=$(APP_NAME).app/Contents/Frameworks
PREFIX=/Applications/$(APP_DIR)
RPATH=@executable_path/../Frameworks/lib

GV_VER=13.1.2
GV_DIR=$(BUILD_DIR)/graphviz-$(GV_VER)
GV_URL=https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/$(GV_VER)/graphviz-$(GV_VER).tar.gz
DOT=dot

UNAME_M:=$(shell uname -m)
ARCH=-arch $(UNAME_M)

#
# Graphviz and App installer package
#
# Note: the check function in Distribution.xml specifies the minimum macOS
# version, which should match the Graphviz.app project's deployment target.
#
# Note: the Component.plist file specifies BundleIsRelocatable = false,
# which forces the app bundle into /Applications. Otherwise, the macOS
# installer, finding the Release build of the app already registered and
# acceptable, DOES NOT install the app into /Applications, and EVENT WORSE
# sets the Release build app's user/group to root/wheel!! Consequently,
# this requires cleanup to use sudo to remove the Release build >:(
#

../graphvizswift-$(UNAME_M).pkg: Component.plist $(BUILD_DIR)/Release/$(APP_NAME).app $(BUILD_DIR)/Release/$(APP_DIR)/bin/$(DOT) $(BUILD_DIR)/Scripts/postinstall
	@echo
	@echo Build Package for the app
	@echo
	rm -rf $(BUILD_DIR)/Release/$(APP_NAME).app.dSYM
	rm -rf $(BUILD_DIR)/Release/$(APP_NAME).swiftmodule
	pkgbuild --root $(BUILD_DIR)/Release --install-location /Applications --scripts $(BUILD_DIR)/Scripts --identifier org.graphviz.app.swift --component-plist $< $@

$(BUILD_DIR)/Release/$(APP_NAME).app: ../$(APP_NAME)/*.swift $(BUILD_DIR)/$(PREFIX)/bin/$(DOT)
	@echo
	@echo Build the app
	@echo
	xcodebuild -project ../$(APP_NAME).xcodeproj -configuration Release VALID_ARCHS=$(UNAME_M) MACOSX_DEPLOYMENT_TARGET=15 ALWAYS_SEARCH_USER_PATHS=NO LIBRARY_SEARCH_PATHS=$(BUILD_DIR)/$(PREFIX)/lib LD_RUNPATH_SEARCH_PATHS=$(RPATH)
	mv $(CURDIR)/$(BUILD_DIR)/$(PREFIX) $(BUILD_DIR)/Release/$(APP_DIR)
	cd $@/Contents/MacOS; dyld_info -linked_dylibs $(APP_NAME) | sed -n -E "s|($(PREFIX)/lib)(.*)|\1\2 @rpath\2 $(APP_NAME)|p" | xargs -t -L1 install_name_tool -change
	codesign -s "-" -fv $@/Contents/MacOS/$(APP_NAME)

$(BUILD_DIR)/Scripts/postinstall:
	@echo
	@echo Generate Script for Post-Install of Package
	@echo
	mkdir -p $(@D)
	echo '#!/bin/sh' >$@
	echo 'logger -is -t "Graphviz Install" "register dot plugins"' >>$@
	echo '"$(PREFIX)/bin/dot" -c' >>$@
	echo 'echo "$(PREFIX)/bin" >/etc/paths.d/graphviz' >>$@
	chmod 755 $@

$(BUILD_DIR)/$(PREFIX)/bin/$(DOT): $(GV_DIR)/cmd/dot/.libs/$(DOT)
	@echo
	@echo Stage Graphviz Libraries for Packaging
	@echo
	make DESTDIR=$(CURDIR)/$(BUILD_DIR) -C $(GV_DIR) install
	rm -rf $(BUILD_DIR)/$(PREFIX)/lib/*.la
	rm -rf $(BUILD_DIR)/$(PREFIX)/lib/graphviz/*.la
	cd $(BUILD_DIR)/$(PREFIX)/bin; find . -type f -maxdepth 1 | while read a;do dyld_info -linked_dylibs $$a | sed -n -E "s|($(PREFIX))(.*)|\1\2 @executable_path/..\2 $$a|p";done | xargs -t -L1 install_name_tool -change
	cd $(BUILD_DIR)/$(PREFIX)/lib; find . -type f -maxdepth 1 | while read a;do dyld_info -linked_dylibs $$a | sed -n -E "s|($(PREFIX)/lib)(.*)|\1\2 @loader_path\2 $$a|p";done | xargs -t -L1 install_name_tool -change
	cd $(BUILD_DIR)/$(PREFIX)/lib/graphviz; find . -type f -maxdepth 1 | while read a;do dyld_info -linked_dylibs $$a | sed -n -E "s|($(PREFIX)/lib)(.*)|\1\2 @loader_path/..\2 $$a|p";done | xargs -t -L1 install_name_tool -change

$(GV_DIR)/cmd/dot/.libs/$(DOT): $(GV_DIR)/Makefile
	@echo
	@echo Building Graphviz
	@echo
	make -C $(GV_DIR)

$(GV_DIR)/Makefile: $(GV_DIR)
	@echo
	@echo Configuring Graphviz
	@echo
	cd $(GV_DIR) && ./configure --prefix=$(PREFIX) --with-quartz --disable-dependency-tracking CFLAGS="-O2 $(ARCH)" CXXFLAGS="-O2 $(ARCH)" OBJCFLAGS="-O2 $(ARCH)" LDFLAGS="$(ARCH) -Wl,-dead_strip"

$(GV_DIR):
	curl --output-dir $(BUILD_DIR) -O -L $(GV_URL)
	tar xzf $(BUILD_DIR)/$(notdir $(GV_URL)) -C $(BUILD_DIR)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/* ../graphvizswift-arm64.pkg


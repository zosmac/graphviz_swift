BUILD_DIR=build
PREFIX=$(CURDIR)/$(BUILD_DIR)/PREFIX
GV_VER=14.0.4
GV_URL=https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/$(GV_VER)/graphviz-$(GV_VER).tar.gz
GV_DIR=$(BUILD_DIR)/graphviz-$(GV_VER)

APP_NAME=GraphvizSwift
APP_DIR=$(APP_NAME).app/Contents/Frameworks
RPATH=@executable_path/../Frameworks/lib

UNAME_M:=$(shell uname -m)
ARCH=-arch $(UNAME_M)

#
# GraphvizSwift App Package Installer
#
# The Component.plist file specifies BundleIsRelocatable = false to force
# the app bundle into /Applications. Otherwise, the macOS installer, finding
# the Release build of the app already registered and acceptable, DOES NOT
# install the app into /Applications, and EVEN WORSE sets the Release build
# content's user/group to root/wheel, requiring the use of sudo to remove it!
#

.PHONY: graphviz
graphviz: clean $(PREFIX)/bin/dot

.PHONY: pkg
pkg: $(PREFIX)/bin/dot graphvizswift-$(UNAME_M).pkg

graphvizswift-$(UNAME_M).pkg: Resources/Component.plist $(BUILD_DIR)/Release/$(APP_NAME).app $(BUILD_DIR)/Scripts/postinstall
	@echo "\n============================="
	@echo Build macOS Package Installer
	@echo "=============================\n"
	rm -rf $(BUILD_DIR)/Release/$(APP_NAME).app.dSYM
	rm -rf $(BUILD_DIR)/Release/$(APP_NAME).swiftmodule
	cp -R $(PREFIX)/ $(BUILD_DIR)/Release/$(APP_DIR)
	pkgbuild --root $(BUILD_DIR)/Release --install-location /Applications --scripts $(BUILD_DIR)/Scripts --identifier org.graphviz.app.swift --component-plist $< $@
	sha512sum $@ >$(@).sha512

$(BUILD_DIR)/Release/$(APP_NAME).app: $(APP_NAME)/*.swift $(PREFIX)/bin/dot Resources/*
	@echo "\n==============="
	@echo Build macOS App
	@echo "===============\n"
	xcodebuild -project $(APP_NAME).xcodeproj -configuration Release ARCHS=$(UNAME_M) LIBRARY_SEARCH_PATHS=$(PREFIX)/lib LD_RUNPATH_SEARCH_PATHS=$(RPATH)
	cd $@/Contents/MacOS; dyld_info -linked_dylibs $(APP_NAME) | sed -n -E "s|($(PREFIX)/lib)(.*)|\1\2 @rpath\2 $(APP_NAME)|p" | xargs -t -L1 install_name_tool -change
	codesign -s "-" -fv $@/Contents/MacOS/$(APP_NAME)

$(BUILD_DIR)/Scripts/postinstall:
	@echo "\n============================"
	@echo Generate Post-Install Script
	@echo "============================\n"
	mkdir -p $(@D)
	echo '#!/bin/sh' >$@
	echo 'logger -is -t "Graphviz Install" "register dot plugins"' >>$@
	echo '/Applications/$(APP_DIR)/bin/dot -c' >>$@
	echo 'echo "/Applications/$(APP_DIR)/bin" >/etc/paths.d/graphviz' >>$@
	chmod 755 $@

$(PREFIX)/bin/dot: $(GV_DIR)/cmd/dot/.libs/dot
	@echo "\n============================"
	@echo Stage Graphviz for Packaging
	@echo "============================\n"
	make -C $(GV_DIR) install
	rm -rf $(PREFIX)/lib/*.la
	rm -rf $(PREFIX)/lib/graphviz/*.la
	cd $(PREFIX)/bin; find . -type f -maxdepth 1 | while read a;do dyld_info -linked_dylibs $$a | sed -n -E "s|($(PREFIX))(.*)|\1\2 @executable_path/..\2 $$a|p";done | xargs -t -L1 install_name_tool -change
	cd $(PREFIX)/lib; find . -type f -maxdepth 1 | while read a;do dyld_info -linked_dylibs $$a | sed -n -E "s|($(PREFIX)/lib)(.*)|\1\2 @loader_path\2 $$a|p";done | xargs -t -L1 install_name_tool -change
	cd $(PREFIX)/lib/graphviz; find . -type f -maxdepth 1 | while read a;do dyld_info -linked_dylibs $$a | sed -n -E "s|($(PREFIX)/lib)(.*)|\1\2 @loader_path/..\2 $$a|p";done | xargs -t -L1 install_name_tool -change

$(GV_DIR)/cmd/dot/.libs/dot: $(GV_DIR)/Makefile
	@echo "\n=============="
	@echo Build Graphviz
	@echo "==============\n"
	make -C $(GV_DIR)

$(GV_DIR)/Makefile: $(GV_DIR)/configure
	@echo "\n=================="
	@echo Configure Graphviz
	@echo "==================\n"
	cd $(GV_DIR) && ./configure --prefix=$(PREFIX) --with-quartz CFLAGS="-Ofast $(ARCH)" CXXFLAGS="-Ofast $(ARCH)" OBJCFLAGS="-Ofast $(ARCH)" OBJCXXFLAGS="-Ofast $(ARCH)" LDFLAGS="$(ARCH) -Wl,-dead_strip"

$(GV_DIR)/configure:
	@echo "\n================="
	@echo Download Graphviz
	@echo "=================\n"
	mkdir -p $(BUILD_DIR)
	curl --output-dir $(BUILD_DIR) -O -L $(GV_URL)
	tar xzf $(BUILD_DIR)/$(notdir $(GV_URL)) -C $(BUILD_DIR)

.PHONY: clean
clean:
	@echo "\n====="
	@echo Clean
	@echo "=====\n"
	rm -rf $(BUILD_DIR) graphvizswift-$(UNAME_M).pkg*


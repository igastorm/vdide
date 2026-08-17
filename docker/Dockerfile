# ==========================================
# バージョン定義 (Builder 用)
# ==========================================
ARG FREERDP_VERSION=2.11.7
ARG FREERDP_SHA512=3a308346b2825a06f60e4c3eaf335c151351ecc6e4b990d63d3ef4da1bc6e6de3fb77aefd041bad4bcb40b9269d9ea8d627ac24786c927e4eaaaac2d4ae4b4b9

ARG GUACAMOLE_VERSION=1.6.0
ARG GUACAMOLE_SERVER_SHA512=7a95ae98556c9fc95170b6e1582198d363677d2e757d7ed45de0064c530f45653f44cd2d22994dc623855b3bd8ef196f2f0ab891b756a123b5b0f5c277e8caee
ARG GUACAMOLE_CLIENT_SHA512=c2914bc4f408221e952d817194575c038b164090a10eb5dbed09401b3312472916417d62b53d45c0587167bc366518b8a1127dd5705c9f1336ae1474f1bc6cf5

ARG PA_XRDP_VERSION=0.8
ARG PA_XRDP_SHA512=45417549d5aa708e063fc93be0f2bbfdac620d57a8073293f67fd3d4fe858c366ab659ff2bf0baabb4ace706760ac7c6c0b6608d8b38176e717a7a9787a3346b

ARG TOMCAT_VERSION=9.0.117
ARG TOMCAT_SHA512=82b15278a7bfa2685c80e07963c43246df4fd742d574b608a68f5ce67c6ffde0eff3e224cc9809925cc6bf7002a190c3bf420f50c0e4052467d3e665efc84a54

# ==========================================
# バージョン定義 (Runtime 用)
# ==========================================
ARG GTEST_VERSION=1.18.0
ARG GTEST_SHA512=ba0f5769ccf34acf1bc72d1f7e9ffb8202176d02b64f6f3d9047accfc0cf9026ff5a653d24935e2705fff8709566676452616c93ca0ca6277f1e21d79b58a10a

ARG CODE_SERVER_VERSION=4.132.0
ARG CODE_SERVER_AMD64_SHA512=0ff5d87baa3074e5aff005bcd12995dc179c0cba43f3afe1c83b6694a781b098319970f116008ac16165ff4d0d9500500f191a14ad50aaf6d89513fed7e7f327
ARG CODE_SERVER_ARM64_SHA512=70b86442e7a009a3a621c5df9b3624b6223357a03710424700537d7b7737e9221a33dff58d70249f59295442a9c5254fdb7d91d8a2052212ccae96d5bbf5e158

ARG CODELLDB_VERSION=1.12.2
ARG CODELLDB_X64_SHA512=8076083c0303101edb46f7bf1ebe88d10c41ef9c399a245af8d30a25069cab9c7ab17c63c448a366dcd74a60b9dd9697b34831442e6738a4f2309514bb7096b9
ARG CODELLDB_ARM64_SHA512=d38a7a484c165638a5675a22b8e3fc9bda35f2c8cd2c72c290531f2c17a5ad800713d04f4a772e860e775c290b497fecfa78fd012166de9c3bd46e13f7ae0e06

# ==========================================
# Base image (common)
# ==========================================
FROM debian:trixie-slim@sha256:4e401d95de7083948053197a9c3913343cd06b706bf15eb6a0c3ccd26f436a0e AS base

# ==========================================
# Stage 1: Base Builder (共通ビルド環境)
# ==========================================
FROM base AS base-builder

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources && \
  apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates sudo dpkg-dev lsb-release doxygen build-essential cmake ninja-build make gcc g++ \
  pkg-config wget unzip libssl-dev libx11-dev libxext-dev libxinerama-dev libxcursor-dev \
  libxkbfile-dev libxv-dev libxi-dev libxfixes-dev libxrandr-dev libxrender-dev libpulse-dev \
  libjpeg-dev libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin libossp-uuid-dev \
  libwebp-dev autoconf automake libtool libapr1-dev default-jdk libopus-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# ==========================================
# Stage 2: FreeRDP Builder
# ==========================================
FROM base-builder AS freerdp-builder
ARG FREERDP_VERSION
ARG FREERDP_SHA512

RUN wget https://github.com/FreeRDP/FreeRDP/archive/refs/tags/${FREERDP_VERSION}.tar.gz && \
  echo "${FREERDP_SHA512} ${FREERDP_VERSION}.tar.gz" | sha512sum -c - && \
  tar -xzf ${FREERDP_VERSION}.tar.gz && cd FreeRDP-${FREERDP_VERSION} && mkdir build && cd build && \
  cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DWITH_WAYLAND=OFF -DWITH_X11=ON -DWITH_ALSA=OFF \
  -DWITH_PULSE=ON -DWITH_CUPS=OFF -DWITH_PCSC=OFF -DWITH_FFMPEG=OFF -DWITH_JPEG=ON \
  -DWITH_CHANNELS=ON -DWITH_CLIENT_CHANNELS=ON -DWITH_SERVER=OFF -DCHANNEL_URBDRC=OFF \
  -DCMAKE_C_FLAGS="-Wno-error -Wno-deprecated-declarations -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration" .. && \
  ninja install

# ==========================================
# Stage 3: Guacamole Server Builder
# ==========================================
FROM freerdp-builder AS guacamole-builder
ARG GUACAMOLE_VERSION
ARG GUACAMOLE_SERVER_SHA512

RUN wget "https://apache.org/dyn/closer.lua/guacamole/${GUACAMOLE_VERSION}/source/guacamole-server-${GUACAMOLE_VERSION}.tar.gz?action=download" -O guac.tar.gz && \
  echo "${GUACAMOLE_SERVER_SHA512} guac.tar.gz" | sha512sum -c - && \
  tar -xzf guac.tar.gz && cd guacamole-server-${GUACAMOLE_VERSION} && \
  ./configure --with-rdp --without-vnc --without-ssh --without-telnet --without-kubernetes --disable-guacenc --disable-guaclog --without-ffmpeg CFLAGS="-Wno-error" && \
  make -j$(nproc) && make install

# ==========================================
# Stage 4: PulseAudio Module xrdp Builder
# ==========================================
FROM base-builder AS pa-xrdp-builder
ARG PA_XRDP_VERSION
ARG PA_XRDP_SHA512

RUN wget https://github.com/neutrinolabs/pulseaudio-module-xrdp/archive/refs/tags/v${PA_XRDP_VERSION}.tar.gz && \
  echo "${PA_XRDP_SHA512} v${PA_XRDP_VERSION}.tar.gz" | sha512sum -c - && \
  tar -xzf v${PA_XRDP_VERSION}.tar.gz && cd pulseaudio-module-xrdp-${PA_XRDP_VERSION} && \
  ./scripts/install_pulseaudio_sources_apt.sh && ./bootstrap && ./configure PULSE_DIR=/root/pulseaudio.src && \
  make -j$(nproc) && make install && mkdir -p /tmp/pa-modules && cp /usr/lib/pulse-*/modules/module-xrdp* /tmp/pa-modules/

# ==========================================
# Stage 5: Tomcat & Guacamole Client Builder
# ==========================================
FROM base-builder AS tomcat-builder
ARG TOMCAT_VERSION
ARG TOMCAT_SHA512
ARG GUACAMOLE_VERSION
ARG GUACAMOLE_CLIENT_SHA512

RUN wget https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
  echo "${TOMCAT_SHA512} apache-tomcat-${TOMCAT_VERSION}.tar.gz" | sha512sum -c - && \
  tar -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz && mv apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat && \
  rm -rf /usr/local/tomcat/webapps/* /usr/local/tomcat/bin/*.bat && \
  mkdir -p /usr/local/tomcat/webapps/ROOT && \
  wget "https://apache.org/dyn/closer.lua/guacamole/${GUACAMOLE_VERSION}/binary/guacamole-${GUACAMOLE_VERSION}.war?action=download" -O /tmp/guac.war && \
  echo "${GUACAMOLE_CLIENT_SHA512} /tmp/guac.war" | sha512sum -c - && \
  unzip /tmp/guac.war -d /usr/local/tomcat/webapps/ROOT/ && \
  tar -xzf /usr/local/tomcat/bin/tomcat-native.tar.gz -C /tmp && cd /tmp/tomcat-native-*/native && \
  ./configure --with-apr=/usr/bin/apr-1-config --with-java-home=/usr/lib/jvm/default-java --with-ssl=yes --prefix=/usr/local/apr && \
  make -j$(nproc) && make install

# ==========================================
# Stage 6: Aggregator & Stripper (成果物の集約と軽量化)
# ==========================================
FROM base AS final-builder

RUN apt-get update && apt-get install -y --no-install-recommends binutils file && rm -rf /var/lib/apt/lists/*

COPY --from=guacamole-builder /usr/local/ /usr/local/
COPY --from=tomcat-builder /usr/local/tomcat/ /usr/local/tomcat/
COPY --from=tomcat-builder /usr/local/apr/ /usr/local/apr/
COPY --from=pa-xrdp-builder /tmp/pa-modules/ /tmp/pa-modules/

# 軽量化: デバッグシンボルの削除し、不要な静的ライブラリ・ヘッダ・マニュアルを排除
RUN find /usr/local/bin /usr/local/sbin /usr/local/lib /usr/local/apr/lib -type f -exec file {} + | grep ELF | cut -d: -f1 | xargs strip --strip-unneeded 2>/dev/null || true && \
  rm -rf /usr/local/include \
  /usr/local/lib/*.a \
  /usr/local/lib/*.la \
  /usr/local/lib/pkgconfig \
  /usr/local/apr/include \
  /usr/local/apr/lib/*.a \
  /usr/local/apr/lib/*.la \
  /usr/local/apr/lib/pkgconfig \
  /usr/local/share/man \
  /usr/local/share/doc

# ==========================================
# Stage 7: Runtime
# ==========================================
FROM base

ARG GTEST_VERSION
ARG GTEST_SHA512

ENV TZ=Asia/Tokyo
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:ja LC_ALL=en_US.UTF-8

RUN echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99-no-languages && \
  echo 'Acquire::Languages::Target "en";' >> /etc/apt/apt.conf.d/99-no-languages && \
  apt-get update && apt-get install -y --no-install-recommends tzdata && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
  dpkg-reconfigure -f noninteractive tzdata && \
  apt-get install -y --no-install-recommends \
  tini sudo locales ca-certificates xrdp xorgxrdp default-jre-headless \
  dbus-x11 dbus-system-bus-common libcairo2 libjpeg62-turbo libpng16-16 libossp-uuid16 \
  libwebp7 libssl3 libx11-6 libxext6 libpulse0 libapr1 libopus0 \
  supervisor libnss-extrausers \
  xfce4 xfce4-taskmanager xfce4-pulseaudio-plugin xfce4-terminal pavucontrol librsvg2-common tango-icon-theme \
  pulseaudio xdg-user-dirs-gtk fonts-ipafont-gothic fcitx5-mozc fcitx5-frontend-gtk3 fcitx5-config-qt \
  llvm \
  clang clang-tools clang-format clang-tidy clangd \
  libclang-rt-dev \
  lldb \
  lld \
  libc++-dev libc++abi-dev \
  libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-net-dev libsdl2-ttf-dev \
  ninja-build cmake curl python3 python3-pip python3-venv git ssh-client && \
  \
  # ==========================================
  # GoogleTest の自前ビルド (libc++ & 例外オフ)
  # ==========================================
  curl -fsSL https://github.com/google/googletest/archive/refs/tags/v${GTEST_VERSION}.tar.gz -o gtest.tar.gz && \
  echo "${GTEST_SHA512} gtest.tar.gz" | sha512sum -c - && \
  tar -xzf gtest.tar.gz && cd googletest-${GTEST_VERSION} && mkdir build && cd build && \
  cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_CXX_FLAGS="-stdlib=libc++ -fno-exceptions" \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  .. && \
  ninja install && \
  cd ../.. && \
  # ビルドが終わったらソースとアーカイブを削除 (軽量化)
  rm -rf googletest-${GTEST_VERSION} gtest.tar.gz && \
  # ==========================================
  (getent group messagebus || groupadd -r messagebus) && \
  (getent passwd messagebus || useradd -r -g messagebus -s /usr/sbin/nologin messagebus) && \
  apt-get clean && \
  find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en*' ! -name 'locale.alias' -exec rm -rf {} + && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/* && \
  sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && update-locale LANG=en_US.UTF-8 && \
  dbus-uuidgen --ensure && \
  rm -rf /usr/share/backgrounds/xfce/*

COPY --from=final-builder /usr/local/ /usr/local/
COPY --from=final-builder /tmp/pa-modules/ /tmp/pa-modules/

# 各種設定ファイルの書き換えとモジュール配置
RUN cp /tmp/pa-modules/* /usr/lib/pulse-*/modules/ && rm -rf /tmp/pa-modules && \
  ldconfig && \
  xrdp-keygen xrdp auto && \
  sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
  sed -i 's/crypt_level=high/crypt_level=none/' /etc/xrdp/xrdp.ini && \
  sed -i 's/tcp_nodelay=true/tcp_nodelay=true/' /etc/xrdp/xrdp.ini && \
  sed -i 's/tcp_nodelay=false/tcp_nodelay=true/' /etc/xrdp/xrdp.ini && \
  sed -i 's/use_fast_path=both/use_fast_path=both/' /etc/xrdp/xrdp.ini && \
  sed -i 's/max_bpp=32/max_bpp=24/' /etc/xrdp/xrdp.ini && \
  sed -i 's/#tcp_send_buffer_bytes=32768/tcp_send_buffer_bytes=4194304/' /etc/xrdp/xrdp.ini && \
  sed -i 's/FuseMountName=thinclient_drives/FuseMountName=/' /etc/xrdp/sesman.ini && \
  sed -i 's/AllowEmptyPassword=false/AllowEmptyPassword=true/' /etc/xrdp/sesman.ini && \
  sed -i 's/load-module module-udev-detect/load-module module-udev-detect tsched=0/g' /etc/pulse/default.pa && \
  sed -i '1i pulseaudio --start\n' /etc/xrdp/startwm.sh && \
  sed -i 's/unpackWARs="true" autoDeploy="true"/unpackWARs="false" autoDeploy="false"/' /usr/local/tomcat/conf/server.xml && \
  # libnss-extrausers の設定と、PAM (認証システム) への pam_extrausers.so の組み込み
  sed -i 's/passwd:.*files/& extrausers/' /etc/nsswitch.conf && \
  sed -i 's/group:.*files/& extrausers/' /etc/nsswitch.conf && \
  sed -i 's/shadow:.*files/& extrausers/' /etc/nsswitch.conf && \
  echo "%sudo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudo_nopasswd && \
  chmod 0440 /etc/sudoers.d/sudo_nopasswd && \
  sed -i '1i auth sufficient pam_extrausers.so nullok' /etc/pam.d/common-auth && \
  sed -i '1i account sufficient pam_extrausers.so' /etc/pam.d/common-account && \
  # tmpfs単一化のためのシンボリックリンク作成
  rm -rf /var/log && ln -s /tmp/log /var/log && \
  rm -rf /var/lib/xrdp && ln -s /tmp/xrdp_lib /var/lib/xrdp && \
  rm -rf /usr/local/tomcat/work && ln -s /tmp/tomcat_work /usr/local/tomcat/work && \
  rm -rf /usr/local/tomcat/temp && ln -s /tmp/tomcat_temp /usr/local/tomcat/temp && \
  rm -rf /usr/local/tomcat/logs && ln -s /tmp/tomcat_logs /usr/local/tomcat/logs && \
  rm -rf /usr/local/tomcat/conf/Catalina && ln -s /tmp/tomcat_catalina /usr/local/tomcat/conf/Catalina && \
  rm -rf /run && ln -s /tmp/run /run && \
  rm -rf /etc/guacamole && ln -s /tmp/guacamole /etc/guacamole && \
  rm -rf /var/lib/extrausers && ln -s /tmp/extrausers /var/lib/extrausers && \
  echo '#!/bin/bash\ncd /home/"$USER_NAME"\nexec sudo -u "$USER_NAME" "$@"' > /usr/local/bin/run-as-user && \
  chmod +x /usr/local/bin/run-as-user && \
  echo "Hidden=true" >> /usr/share/applications/xfce4-mail-reader.desktop && \
  echo "Hidden=true" >> /usr/share/applications/xfce4-session-logout.desktop && \
  echo "Hidden=true" >> /usr/share/applications/xfce4-web-browser.desktop && \
  echo "Hidden=true" >> /usr/share/applications/org.fcitx.fcitx5-migrator.desktop && \
  sed -i 's/TerminalEmulator=debian-x-terminal-emulator/TerminalEmulator=xfce4-terminal/' /etc/xdg/xfce4/helpers.rc

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD ["sh", "-c", "curl -fsS http://localhost:8080 -o /dev/null && curl -fsS http://localhost:3000 -o /dev/null || exit 1"]

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY supervisord-template.conf /usr/local/etc/supervisord-template.conf
COPY user-mapping-template.xml /usr/local/etc/user-mapping-template.xml
COPY settings.json /usr/local/etc/settings.json
COPY desktop-setup.sh /usr/local/bin/desktop-setup.sh
RUN chmod +x /usr/local/bin/desktop-setup.sh && chmod +x /usr/local/bin/entrypoint.sh
# ==========================================
# code-server (更新が多めなので後ろに記述)
# ==========================================
ARG CODE_SERVER_VERSION
ARG CODE_SERVER_AMD64_SHA512
ARG CODE_SERVER_ARM64_SHA512

ARG CODELLDB_VERSION
ARG CODELLDB_X64_SHA512
ARG CODELLDB_ARM64_SHA512

RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
  CS_ARCH="amd64"; \
  CS_SHA512="${CODE_SERVER_AMD64_SHA512}"; \
  CODELLDB_ARCH="x64"; \
  CODELLDB_SHA512="${CODELLDB_X64_SHA512}"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  CS_ARCH="arm64"; \
  CS_SHA512="${CODE_SERVER_ARM64_SHA512}"; \
  CODELLDB_ARCH="arm64"; \
  CODELLDB_SHA512="${CODELLDB_ARM64_SHA512}"; \
  else \
  echo "Unsupported architecture: $ARCH" && exit 1; \
  fi && \
  # code-server のダウンロードと検証
  curl -fsSL "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-${CS_ARCH}.tar.gz" -o /tmp/code-server.tar.gz && \
  echo "${CS_SHA512} /tmp/code-server.tar.gz" | sha512sum -c - && \
  tar -xzf /tmp/code-server.tar.gz -C /usr/local && \
  mv /usr/local/code-server-${CODE_SERVER_VERSION}-linux-${CS_ARCH} /usr/local/code-server && \
  # CodeLLDB のダウンロードと検証
  curl -fsSL "https://github.com/vadimcn/codelldb/releases/download/v${CODELLDB_VERSION}/codelldb-linux-${CODELLDB_ARCH}.vsix" -o /tmp/codelldb.vsix && \
  echo "${CODELLDB_SHA512} /tmp/codelldb.vsix" | sha512sum -c - && \
  mkdir -p /tmp/vscode-exts && \
  /usr/local/code-server/bin/code-server \
  --extensions-dir /tmp/vscode-exts \
  --install-extension llvm-vs-code-extensions.vscode-clangd \
  --install-extension ms-vscode.cmake-tools \
  --install-extension ms-vscode.hexeditor \
  --install-extension /tmp/codelldb.vsix \
  --install-extension ms-python.python \
  --install-extension ms-python.debugpy \
  --install-extension charliermarsh.ruff && \
  mv /tmp/vscode-exts/* /usr/local/code-server/lib/vscode/extensions/ && \
  # クリーンアップ
  rm -rf /tmp/code-server.tar.gz /tmp/codelldb.vsix /tmp/vscode-exts

EXPOSE 8080
EXPOSE 3000
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

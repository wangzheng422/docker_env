#!/bin/bash
main() {
  purge_old
  install_deps
  install
}

purge_old() {
   log info "-----purge old-----"
}

install_deps() {
   log info "-----install deps-----"
}

install() {
  log info "-----install-----"
  cd  $RPM_DIR/lib/ipp
  ./install.sh -s ipp.wzh.cfg
  cd  $RPM_DIR/lib/mkl
  ./install.sh -s mkl.wzh.cfg
  echo "source  /opt/intel/compilers_and_libraries_2018/linux/bin/compilervars.sh  intel64" >> /root/.bashrc  
  cp $RPM_DIR/lib/libstdc++.so.6.0.21  /lib64/
  rm /lib64/libstdc++.so.6 || true
  ln -s /lib64/libstdc++.so.6.0.21 /lib64/libstdc++.so.6 || true
}

main

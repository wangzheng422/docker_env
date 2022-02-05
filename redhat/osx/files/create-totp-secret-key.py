#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import base64
import getpass

if __name__ == '__main__':
    try:
        p1 = getpass.getpass(prompt='Enter a password: ')
        p2 = getpass.getpass(prompt='Confirm the password: ')
        if p1 != p2:
            print('The passwords do not match!')
            sys.exit(1)

        password = bytes(p1, 'utf-8')
        print('Base16 encoded: ', base64.b16encode(password))
        print('Base32 encoded: ', base64.b32encode(password))
    except Exception as e:
        print('ERROR', e)

#!/bin/bash

# Generate CA
echo -e "\r\n- Generate CA\r"
openssl req -new -newkey rsa:2048 -nodes -out ./ca.csr -keyout ./ca.key -extensions v3_ca -subj "/CN=ca.self.signed"
openssl x509 -signkey ./ca.key -days 365 -req -in ./ca.csr -set_serial 01 -out ./ca.crt

# Generate Intermediate CA
echo -e "\r\n- Generate Intermediate CA\r"
openssl req -new -newkey rsa:2048 -nodes -out ./inter.csr -keyout ./inter.key -addext basicConstraints=CA:TRUE -subj "/CN=intermediate.ca.self.signed"
openssl x509 -CA ./ca.crt -CAkey ./ca.key -days 365 -req -in ./inter.csr -set_serial 02 -out ./inter.crt

# Generate request for target certificate
echo -e "\r\n- Generate CSR\r"
openssl req -new -newkey rsa:2048 -nodes -out ./test.csr -keyout ./test.key -subj "/CN=test.self.signed"

# Sign the request for target certificate using intermediate CA
echo -e "\r\n- Sign CSR using Intermediate CA\r"
openssl x509 -CA ./inter.crt -CAkey ./inter.key -days 365 -req -in ./test.csr -set_serial 03 -out ./test.crt

# Export test certificate with private key and the chain certificates to PFX
echo -e "\r\n- Export all in PFX"
openssl pkcs12 -export -inkey ./test.key -in ./test.crt -certfile ./inter.crt -passout pass: -out ./server.p12

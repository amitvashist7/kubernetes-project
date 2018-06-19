## Retrieve keys from kops
```
aws s3 sync s3://kops-state-b429b/kubernetes.newtech.academy/pki/private/ca/ ca-key
aws s3 sync s3://kops-state-b429b/kubernetes.newtech.academy/pki/issued/ca/ ca-crt
mv ca-key/*.key ca.key
mv ca-crt/*.crt ca.crt
```
## Create new user
```
sudo apt install openssl
openssl genrsa -out amit.pem 2048
openssl req -new -key amit.pem -out amit-csr.pem -subj "/CN=amit/O=myteam/"
openssl x509 -req -in amit-csr.pem -CA ca.crt -CAkey ca.key -CAcreateserial -out amit.crt -days 10000
```

## add new context
```
kubectl config set-credentials amit --client-certificate=amit.crt --client-key=amit.pem
kubectl config set-context amit --cluster=kubernetes.newtech.academy --user amit
```

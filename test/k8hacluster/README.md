
Setting up a Kubernetes HA cluster on Bare Metal:
=================================================

**Requirements:**

 - Three Ubuntu nodes minimum (these would be master nodes)
    - This will handle at least one master failure. To handle two master failures, we need five master nodes.
 - Worker nodes (optional can be 0 to n)
 - Virtual IP (for keepalived)

**Setup:**

1. Prep the systems:
	- Turn off swap on all the nodes (sudo swapoff -a)
	- Turn off firewall if enabled.
	- If these nodes are brand new, install Docker and Kubernetes packages.

2. Run etcd as a docker container on each node.
	- Edit etcd/initetcd.sh with the IP addresses (HOST_1, HOST_2, HOST_3)  and names (NAME_1, NAME_2, NAME_3) of the three nodes.
	- Copy and run the script on each of the three masters.
          	NOTE: On each node the values (NODE_NAME & NODE_IP) in the script must be modified to take in the right hostname (NAME_1, NAME_2, NAME_3) and IP (HOST_1, HOST_2, HOST_3)  
	- This will start etcd docker container on all the three nodes.
	- To test the installation (to see if all the three nodes are members of the etcd cluster):
	  $ docker exec etcd /bin/sh -c "export ETCDCTL_API=3 && /usr/local/bin/etcdctl member list"

3. Run the kubeadm init setup to setup the first master.
	- Edit the kubeClusterInitConfig/kubeadm-init.yaml file with the IP addresses and the names of the three nodes. 
          NOTE: the virtual IP has to be added to the apiServerCertSANs field along with the master nodes IP's and names.
	- Run:
	  ```
	  $ sudo kubeadm init --ignore-preflight-errors=all --config kubeadm-init.yaml
	  ```
	- Once completed, follow the instructions provided as part of the output to create the .kube folder, copying the config etc.
	```	
		$ mkdir -p $HOME/.kube
		$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
		$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
	```
	- Apply the flannel networking config:
	```
		$ sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
	```
	- Run:
		```
		$ kubectl get nodes
		$ kubectl get pods --all-namespaces -o=wide
		```
		
	Make sure that there is one master and the pods are all running well. If the node is NotReady (ideally it should be Ready), wait for some time for it to be Ready. Same with the pods as well, make sure that the pods are all Running without any issues before initing the other master's.
	
If after waiting for few minutes, the master is still in NotReady state or the pods are restarting or not all are in Running state, something is wrong. Try restarting the kubelet (sudo service kubelet restart). If this does not solve the problem, look for troubleshooting steps.

	- Copy the kubernetes certificates from the first master (the one where the above init command ran successfully) to the second and third master nodes.
	```
	$ sudo scp /etc/kubernetes/pki/* user@<master-2 ip>:/home/user/pki/
	$ sudo scp /etc/kubernetes/pki/* user@<master-3 ip>:/home/user/pki/
	```	
	- Copy the config (kubeClusterInitConfig/kubeadm-init.yaml)  to all the three nodes and modify the nodeName in the yaml to the node name where the config has to be run.
		- Move the pki certificates to /etc/kubernetes/pki and run kubeadm init:
		  ```	
		  $ sudo mv pki/* /etc/kubernetes/pki/
		  $ sudo kubeadm init --ignore-preflight-errors=all --config kubeadm-init.yaml
		  ```
	  	NOTE: When the kubeadm init runs, the output generated differs from the output generated when init was run on the first node. This is expected.

		Once completed, follow the instructions provided as part of the output to create the .kube folder, copying the config etc.
		```
		$ mkdir -p $HOME/.kube
		$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config	          
		$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
		```
		NOTE: Network config(flannel) needs to be applied only on the first master node. We need not apply it again on subsequent masters.
         	- Run:
	 	```
		$ kubectl get nodes	
		NAME             STATUS    ROLES     AGE       VERSION
		k8-node-a   Ready     master    1h        v1.11.1
		k8-node-b   Ready     master    1h        v1.11.1
		k8-node-c   Ready     master    1h        v1.11.1
		
		$ kubectl get pods --all-namespaces -o=wide
		NAMESPACE     NAME                                     READY     STATUS    RESTARTS   AGE       IP               NODE
		kube-system   coredns-78fcdf6894-w7wtf            1/1       Running   0          1h        10.244.0.7       k8-node-a
		kube-system   coredns-78fcdf6894-zztcm            1/1       Running   0          1h        10.244.0.5       k8-node-a
		kube-system   kube-apiserver-k8-node-a            1/1       Running   0          1h        10.244.120.123   k8-node-a
		kube-system   kube-apiserver-k8-node-b            1/1       Running   0          1h        10.244.120.124   k8-node-b
		kube-system   kube-apiserver-k8-node-c            1/1       Running   0          1h        10.244.120.164   k8-node-c
		kube-system   kube-controller-manager-k8-node-a   1/1       Running   0          1h        10.244.120.123   k8-node-a
		kube-system   kube-controller-manager-k8-node-b   1/1       Running   0          1h        10.244.120.124   k8-node-b
		kube-system   kube-controller-manager-k8-node-c   1/1       Running   0          1h        10.244.120.164   k8-node-c
		kube-system   kube-flannel-ds-76q6s               1/1       Running   0          1h        10.244.120.124   k8-node-b
		kube-system   kube-flannel-ds-8nsjn               1/1       Running   0          1h        10.244.120.164   k8-node-c
		kube-system   kube-flannel-ds-vpxkf               1/1       Running   0          1h        10.244.120.123   k8-node-a
		kube-system   kube-proxy-cqmm6                    1/1       Running   0          1h        10.244.120.124   k8-node-b
		kube-system   kube-proxy-lffj5                    1/1       Running   0          1h        10.244.120.123   k8-node-a
		kube-system   kube-proxy-w2sn2                    1/1       Running   0          1h        10.244.120.164   k8-node-c
		kube-system   kube-scheduler-k8-node-a            1/1       Running   0          1h        10.244.120.123   k8-node-a
		kube-system   kube-scheduler-k8-node-b            1/1       Running   0          1h        10.244.120.124   k8-node-b
		kube-system   kube-scheduler-k8-node-c            1/1       Running   0          1h        10.244.120.164   k8-node-c
		
		```
		This will show the number of masters and the state of the pods. It may take few minutes for all the pods to be running and the nodes to turn 'Ready'.
		Some pods restart once or twice that should be ok. But, they should not be crash loop.

4. Install Keepalived.
	- Follow keepalived/README.

5. Install nginx load balancer to access the api server.
	- Follow nginx-lb/README.

6. To add workers to the cluster:
	
	- On one of the masters:
		```
		$ sudo kubeadm token create
		3k8a5g.aue65i8z54z4xd7x
		
		$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
		4908ea01832102792d641f3359efbfc8dfc64ad924128be0484f88b3933a6d27
		```
		- On the worker node:
	
		```
		$ sudo kubeadm join <master-ip>:6443 --token 3k8a5g.aue65i8z54z4xd7x --discovery-token-ca-cert-hash sha256:4908ea01832102792d641f3359efbfc8dfc64ad924128be0484f88b3933a6d27
		```
		
		After the join completes successfully:
		```
		$ sed -i "s/<master-1 ip>:6443/<virtual ip>:16443/g" /etc/kubernetes/bootstrap-kubelet.conf
		$ sed -i "s/<master-2 ip>:6443/<virtual ip>:16443/g" /etc/kubernetes/bootstrap-kubelet.conf
		$ sed -i "s/<master-3 ip>:6443/<virtual ip>:16443/g" /etc/kubernetes/bootstrap-kubelet.conf
		
		$ sed -i "s/<master-1 ip>:6443/<virtual ip>:16443/g" /etc/kubernetes/kubelet.conf
		$ sed -i "s/<master-2 ip>:6443/<virtual ip>:16443/g" /etc/kubernetes/kubelet.conf
		$ sed -i "s/<master-3 ip>:6443/<virtual ip>:16443/g" /etc/kubernetes/kubelet.conf

		$ grep 'virtual ip' /etc/kubernetes/*.conf 
		/etc/kubernetes/bootstrap-kubelet.conf:    server: https://<virtual ip>:16443
		/etc/kubernetes/kubelet.conf:    server: https://<virtual ip>:16443

		$ sudo systemctl restart docker kubelet
		```
	- On the master:
		- Run:
		```
		  $ kubectl get nodes
		```
		To see if the worker node is added successfully. It may not have a label ('worker') that can be set manually later.

7. To make master node's schedulable.
	- Run:
	```
		$ kubectl taint nodes --all node-role.kubernetes.io/master-
	```
	- To get list of nodes that are scheduleable:
	```
		$ kubectl get nodes -o go-template='{{range .items}}{{with $x := index .metadata.annotations "scheduler.alpha.kubernetes.io/taints"}}{{.}}{{end}}{{end}}'
	```
8. To test the cluster:

	- On any master:
   	
	```
	$ kubectl run nginx --image=nginx --replicas=3 --port=80
	deployment.apps/nginx created

	$ kubectl get pods -l=run=nginx -o wide
	NAME                     READY     STATUS    RESTARTS   AGE       IP           NODE
	nginx-6f858d4d45-mdtnw   1/1       Running   0          11s       10.244.2.2   k8-node-c
	nginx-6f858d4d45-nzsdm   1/1       Running   0          11s       10.244.1.2   k8-node-b
	nginx-6f858d4d45-x77w4   1/1       Running   0          11s       10.244.0.8   k8-node-a

	$ kubectl expose deployment nginx --type=NodePort --port=80
	service/nginx exposed

	$ kubectl get svc -l=run=nginx -o wide
	NAME      TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE       SELECTOR
	nginx     NodePort   10.100.190.219   <none>        80:30908/TCP   9s        run=nginx
		
	NOTE: 
		1. https does not work as nginx is running http only
		2. The port # used below in the curl command is from the PORT(S) field in the above command output.

	$ curl http://<virtual ip>:30908
	<!DOCTYPE html>
	<html>
	<head>
	<title>Welcome to nginx!</title>
	<style>
	    body {
	        width: 35em;
	        margin: 0 auto;
	        font-family: Tahoma, Verdana, Arial, sans-serif;
	    }
	</style>
	</head>
	<body>
	<h1>Welcome to nginx!</h1>
	<p>If you see this page, the nginx web server is successfully installed and
	working. Further configuration is required.</p>
	
	<p>For online documentation and support please refer to
	<a href="http://nginx.org/">nginx.org</a>.<br/>
	Commercial support is available at
	<a href="http://nginx.com/">nginx.com</a>.</p>
	
	<p><em>Thank you for using nginx.</em></p>
	</body>
	</html>
	$
	```
	
	- POD connectivity test:
	
	```
		$ kubectl run nginx-server --image=nginx --port=80
		deployment.apps/nginx-server created

		$ kubectl expose deployment nginx-server --port=80
		service/nginx-server exposed

		$ kubectl get pods -o wide -l=run=nginx-server
		NAME                            READY     STATUS    RESTARTS   AGE       IP           NODE
		nginx-server-6bdb9998f7-fk54d   1/1       Running   0          16s       10.244.2.3   k8-node-c

		$ kubectl run nginx-client -ti --rm --image=alpine -- ash
		If you don't see a command prompt, try pressing enter.

		/ # wget nginx-server
		Connecting to nginx-server (xxx.xxx.xxx.xxx:80)
		index.html           100% |*******************************************|   612   0:00:00 ETA

		/ # cat index.html
		<!DOCTYPE html>
		<html>
		<head>
		<title>Welcome to nginx!</title>
		<style>
		    body {
		        width: 35em;
		        margin: 0 auto;
		        font-family: Tahoma, Verdana, Arial, sans-serif;
		    }
		</style>
		</head>
		<body>
		<h1>Welcome to nginx!</h1>
		<p>If you see this page, the nginx web server is successfully installed and
		working. Further configuration is required.</p>
		
		<p>For online documentation and support please refer to
		<a href="http://nginx.org/">nginx.org</a>.<br/>
		Commercial support is available at
		<a href="http://nginx.com/">nginx.com</a>.</p>
		
		<p><em>Thank you for using nginx.</em></p>
		</body>
		</html>
		/ #
		/ # Session ended, resume using 'kubectl attach nginx-client-65975cddb-fcnf2 -c nginx-client -i -t' command when the pod is running
		deployment.apps "nginx-client" deleted

		$ kubectl delete deploy,svc nginx-server
		deployment.extensions "nginx-server" deleted
		service "nginx-server" deleted
		```

### Troubleshooting: ###


1. How to reset the system if something goes wrong:
	- Remove nginx load balancer if installed. Follow the Troubleshooting section in nginx-lb/README .
	- Run kubeClusterInitConfig/cleanup.sh on all the nodes.
	```
		$ sudo sh cleanup.sh
	```

2. Upon master nodes restart:
	- Make sure the etcd, keepalived and the nginx-lb are running. If not running, start the old container manually.
	- Check if swap is still turned off. Otherwise turn it off using 'sudo swapoff -a'.
	- Restart the kubelet if either or both of the above operations are performed.
	```
		$ sudo service kubelet restart
	```

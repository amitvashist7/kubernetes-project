ETCD_VERSION=3.2
TOKEN=my-etcd-token
CLUSTER_STATE=new
NAME_1=k8s-master-a
NAME_2=k8s-master-b
NAME_3=k8s-master-c
HOST_1=10.142.0.15
HOST_2=10.142.0.16
HOST_3=10.142.0.17
CLUSTER=${NAME_1}=http://${HOST_1}:2380,${NAME_2}=http://${HOST_2}:2380,${NAME_3}=http://${HOST_3}:2380
DATA_DIR=/var/lib/etcd

# For node 3
NODE_NAME=${NAME_3}
NODE_IP=${HOST_3}
docker run --restart always -d \
  -p 2379:2379 \
  -p 2380:2380 \
  --volume=${DATA_DIR}:/etcd-data \
  --name etcd quay.io/coreos/etcd:${ETCD_VERSION} \
  /usr/local/bin/etcd \
  --data-dir=/etcd-data --name ${NODE_NAME} \
  --initial-advertise-peer-urls http://${NODE_IP}:2380 --listen-peer-urls http://0.0.0.0:2380 \
  --advertise-client-urls http://${NODE_IP}:2379 --listen-client-urls http://0.0.0.0:2379 \
  --initial-cluster ${CLUSTER} \
  --initial-cluster-state ${CLUSTER_STATE} --initial-cluster-token ${TOKEN}

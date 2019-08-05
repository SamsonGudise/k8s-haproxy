# Proxy to Remote (kubeapi) Kubernetes cluster
## kubectl to  kubeapi via haproxy - TCP/Layer 4

## Install Instructions
1. **Clone this project**
    ```
    git clone <project link>
    ```
1. **Edit haproxy.cfg**

    Edit `haproxy.cfg` replace `api.internal.deploy.euw1.infradev.sarithm.biz` with your cluster internal route53 record.
    ```
    server apiserver1 api.internal.ssrv.euw1.shopdev.sarithm.biz:443
    ```  
1. **haprxoy.cfg explained**

    set mode `mode=tcp`. i.e., Configure haproxy to work at Layer4/TCP
     ```
     .
     .
    defaults
        log     global
        mode    tcp
    .
    .
    frontend k8s-api
        bind 0.0.0.0:443
        bind 127.0.0.1:443
        mode tcp
    .
    .
    backend k8s-api
        mode tcp
        option tcp-check
        balance roundrobin
        .
    ```
1. **Edit haproxy-deployment.yaml**

    Set Container port to 443 as haproxy image configured to bind on 443.
    ```
        spec:
      containers:
      - name: haproxy
        image: samsonbabu/haproxy:0.2
        ports:
        - containerPort: 443
    ```
1. **haproxy-service**
    Set Service annotation to configure ELB for Layer4/TCP
    ```
    annotations:
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
    ```
    ## Time to Push Changes to Cluster

1. **Create Configmap**
    ```
    kubectl --context=gateway.euw1.infradev.sarithm.biz create configmap ssrv-kubeapi-config --from-file=haproxy.cfg=haproxy.cfg -n l4proxy    
    ```
1. **Create Deployment & Service**
    ```
    kubectl --context=gateway.euw1.infradev.sarithm.biz apply -f haproxy-deployment.yaml -n l4proxy
    ```
1. **Query Service for AWS ELB**
    ```
    admin@ip-10-63-16-15:~$ kubectl --context=gateway.euw1.infradev.sarithm.biz get service ssrv-kubeapi -n l4proxy
    NAME           TYPE           CLUSTER-IP     EXTERNAL-IP                                                               PORT(S)         AGE
    ssrv-kubeapi   LoadBalancer   100.64.23.43   a43c187b69e2111e9800d065aa8ba7c0-1037423763.eu-west-1.elb.amazonaws.com   443:32169/TCP   14h
    admin@ip-10-63-16-15:~$
    ```
1. **Create Route53 CNAME record with ELB value**

    AWS Console(shopdev)  -> Route53 -> shopdev.sarithm.biz -> Create Record Set -> Name : ssrv.euw1 -> value : a43c187b69e2111e9800d065aa8ba7c0-1037423763.eu-west-1.elb.amazonaws.com -> Create

## Test
        
    C02WX83HJG5J:k8s-haproxy sgudise$ ./k8s-auzre.sh sgudise ssrv.euw1.shopdev.sarithm.biz

    Cluster "ssrv.euw1.shopdev.sarithm.biz" set.
    User "sgudise" set.
    Context "ssrv.euw1.shopdev.sarithm.biz" created.
    Switched to context "ssrv.euw1.shopdev.sarithm.biz".
    To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code BB3UWRY62 to authenticate.
## Troubleshoot
1. **Login `Bastion` to troubleshoot**
      
      ```
      C02WX83HJG5J:~ sgudise$ ssh admin@bastion-gateway-euw1-infr-4a9jmf-1936817435.eu-west-1.elb.amazonaws.com
      ```
1. **Pods up and running**
    ```
      admin@ip-10-63-16-15:~$ kubectl get pods -n l4proxy --context=gateway.euw1.infradev.sarithm.biz
      NAME                                          READY   STATUS    RESTARTS   AGE
      deploy-ingress-deployment-5c68459865-mh7h8    1/1     Running   0          3h
      deploy-kubeapi-deployment-5dbfd7c545-sjz67    1/1     Running   0          4h
      gateway-kubeapi-deployment-74ddbfbbcb-cl42w   1/1     Running   0          4h
      ssrv-kubeapi-deployment-5756c5cb74-zrk2j      1/1     Running   0          1d
    ```
 1. **List configmaps**

    
        admin@ip-10-63-16-15:~$ kubectl get configmap -n l4proxy --context=gateway.euw1.infradev.sarithm.biz
        NAME                     DATA   AGE
        deploy-ingress-config    1      3h
        deploy-kubeapi-config    1      5h
        gateway-kubeapi-config   1      4h
        ssrv-kubeapi-config      1      1d

1. **List haproxy services**

      ```
      admin@ip-10-63-16-15:~$ kubectl get services  -n l4proxy --context=gateway.euw1.infradev.sarithm.biz
      NAME              TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)         AGE
      deploy-ingress    LoadBalancer   100.70.181.26   a5089f2769f5811e9800d065aa8ba7c0-355376117.eu-west-1.elb.amazonaws.com    443:30050/TCP   3h
      deploy-kubeapi    LoadBalancer   100.66.42.54    aa78a179c9f4c11e98b7c02c7ee95710-620068197.eu-west-1.elb.amazonaws.com    443:30080/TCP   4h
      gateway-kubeapi   LoadBalancer   100.66.189.20   ab0283d989f5111e9800d065aa8ba7c0-1589958296.eu-west-1.elb.amazonaws.com   443:30755/TCP   4h
      ssrv-kubeapi      LoadBalancer   100.64.23.43    a43c187b69e2111e9800d065aa8ba7c0-1037423763.eu-west-1.elb.amazonaws.com   443:32169/TCP   1d
      admin@ip-10-63-16-15:~$
      
      
1. **Check `haproxy.cfg`**

        admin@ip-10-63-16-15:~$ kubectl get configmap deploy-kubeapi-config  -n l4proxy --context=gateway.euw1.infradev.sarithm.biz -o yaml
        apiVersion: v1
        data:
            haproxy.cfg: "global\n    log /dev/log    local0\n    log /dev/log    local1 notice\n
            \   user haproxy\n    group haproxy\n    daemon\n\ndefaults\n    log     global\n
            \   mode    tcp\n    option  tcplog\n    option  dontlognull\n    timeout connect
            5000\n    timeout client  50000\n    timeout server  50000\n\nfrontend k8s-api\n
            \   bind 0.0.0.0:443\n    bind 127.0.0.1:443\n    mode tcp\n    option tcplog\n
            \   default_backend k8s-api\n\nbackend k8s-api\n    mode tcp\n    option tcp-check\n
            \   balance roundrobin\n    default-server inter 10s downinter 5s rise 2 fall
            2 slowstart 60s maxconn 250 maxqueue 256 weight 100\n\tserver apiserver1 api.internal.deploy.euw1.infradev.sarithm.biz:443
            check\n"
        kind: ConfigMap
        metadata:
            creationTimestamp: "2019-07-05T17:37:37Z"
            name: deploy-kubeapi-config
            namespace: l4proxy
            resourceVersion: "1164185"
            selfLink: /api/v1/namespaces/l4proxy/configmaps/deploy-kubeapi-config
            uid: 94555f37-9f4b-11e9-800d-065aa8ba7c04
        admin@ip-10-63-16-15:~$


1. **HAPRXOY ELB**

    Login to AWS(Infradev) Console and check classic LoadBalancer.  Make sure Instance status `InService`

1. **Kubernetes Master(kubeapi)**
    
    Make sure your cluster(kubeapi) can  be reachable from haproxy pod
    Login to `Gateway cluster Node` and run command below 
    ```
    $ curl -k https://api.internal.ssrv.euw1.shopdev.sarithm.biz
    {
    "kind": "Status",
    "apiVersion": "v1",
    "metadata": {

    },
    "status": "Failure",
    "message": "Unauthorized",
    "reason": "Unauthorized",
    "code": 401
    }    

Note: If fails, update `masters` security group to include `All TCP` from `10.63.0.0\16`

## Enhancement
1. **Add Required tools**
    
    Image does not include basic tools, add tools such as `ps` or `netstat` etc.,

1. **Bestpractices**
    
    It is POC image, apply best practices.  Build image to run haproxy as non-root user.

1. **Dockerfile**
    Build haproxy image with custom `haproxy.cfg` file.  
    ```
    FROM haproxy:2.0
    RUN  groupadd -r haproxy && useradd --no-log-init -r -g haproxy haproxy
    ```
    Note: haproxy.cfg  will come from kubernetes `configmap` and `volumes` objects.

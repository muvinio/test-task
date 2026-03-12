# Задание 1

## Условие

Для файла access.log вывести список с суммарным объемом данных,
который передал сервер для каждого IP-адреса в формате:

1338 bytes for 1.2.3.4  
100500 bytes for 123.23.1.2  

В качестве ответа на вопрос напишите bash-однострочник.


## Решение

### awk '{sum[$1]+=$10} END {for (ip in sum) printf "%d bytes for %s\n", sum[ip], ip}' access.log


# Задание 2

## Условие

Используя lsof необходимо вывести список всех ESTABLISHED TCP
соединений. В качестве ответа на вопрос напишите bash-однострочник.


## Решение

### lsof -iTCP -sTCP:ESTABLISHED


# Задание 3

## Условие

По скриншоту мониторинга определите причину недоступности сервиса.
Определите время недоступности.


## Решение

По графикам мониторинга видно, что около 13:00 резко увеличилось количество подключений к базе данных.

1. **MySQL Connections**
   - значение **Max Used Connections** резко выросло до ~3000
   - график упирается в лимит Max Connections = 3000

2. **MySQL Client Thread Activity**
   - параметр **Threads Connected** также вырос до 3000

3. **MySQL Questions**
   - до ~13:00 выполнялось около 6000–7000 запросов
   - после ~13:00 количество запросов практически упало до 0


## Причина недоступности

Сервер **MySQL достиг лимита `max_connections`**, поэтому новые подключения начали отклоняться.

В результате приложение не могло установить соединение с базой данных, что привело к недоступности веб-сервиса.

Типичная ошибка в таких случаях:

**Too many connections**

## Время недоступности

По графику:

- начало проблемы — примерно 13:00
- до ~13:20 количество запросов остается близким к нулю

**Время недоступности:** начало ~13:00 и продолжалось как минимум до конца отображаемого периода мониторинга


# Задание 4

## Условие

Ниже представлен манифест Dockerfile, который содержит несколько
недочетов.
В качестве ответа укажите на текущие проблемы, оставив комментарий
по каждой инструкции, и опишите, как их можно исправить, оптимизировав
при этом использование слоев итогового образа.

Исходный Dockerfile:

---
FROM ubuntu:latest
MAINTAINER MyCompany
COPY . /var/www/html
RUN apt-get update -y
RUN apt-get install -y nginx
CMD ["nginx", "-g", "daemon off;"]
---

`FROM ubuntu:latest` - тэг **latest** может привести к неожиданным ошибкам при обновлении образа. Лучше указать конкретную версию

`MAINTAINER MyCompany` - инструкция MAINTAINER устарела. Лучше использовать LABEL

`COPY . /var/www/html` - копируется весь контекст сборки, включая ненужные файлы. Нужно использовать .dockerignore

`RUN apt-get update -y`
`RUN apt-get install -y nginx` - Создается лишний слой. Лучше объеденить в одну команду и удалить кэш

## Результат

FROM ubuntu:22.04
LABEL maintainer="MyCompany"

RUN apt-get update -y \
 && apt-get install -y nginx \
 && rm -rf /var/lib/apt/lists/*

COPY . /var/www/html

CMD ["nginx", "-g", "daemon off;"]


# Задание 5

## Условие

Вы отвечаете за доступность проекта. Внезапно на одном из узлов
перестает отвечать веб-сервер Nginx. Пользователи сообщают о том,
что не могут получить доступ к веб-сайту, обслуживаемому этим
веб-сервером.
В качестве ответа опишите действия, которые вы бы предприняли для
диагностики и решения проблемы, чтобы минимизировать время простоя
сервиса.

## Шаги диагностики

### 1. Проверка доступности сервера

Сначала необходимо убедиться, что сам сервер доступен.

**ping server_ip**

`Если сервер недоступен, необходимо проверить:`

 `- состояние виртуальной машины`
 `- сетевые правила firewall`
 `- сетевую инфраструктуру` 

Проверить, запущен ли Nginx.

**systemctl status nginx**

Проверить, слушает ли он порты

**ss -tlnp | grep :80**
**netstat -tlnp | grep nginx**


Проверить конфигурацию Nginx

**nginx -t**

`Если обнаружена ошибка, необходимо исправить конфигурацию и перезапустить сервис:`

 `systemctl restart nginx`

Перезапустить сервис

**systemctl restart nginx**

**pkill -9 nginx**
**systemctl start nginx**

Проверить логи

**tail -n 100 /var/log/nginx/error.log**
**tail -n 100 /var/log/nginx/access.log**

Проверить ресурсы сервера

**top**
**free -h**
**df -h**


# Задание 6

## Условие

Есть образ с сервисом, который запускается локально командой:

docker run -d -p 8080:80 --name my-app my-app-image

Нужно развернуть его в Kubernetes, чтобы оно было доступно снаружи
кластера, устойчиво к сбоям (например, перезапускалось при падении) и
могло легко масштабироваться. Опишите шаги и манифесты для
развертывания.

## Решение

1. Создаем Deployment для управления подами и обеспечения отказоустойчивости

```
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3 
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app-image:latest #лучше указывать конкретную версию
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
```

2. Создаем Service для доступа к приложению внутри или снаружи кластера

```
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app-service
  labels:
    app: my-app
spec:
  selector:
    app: my-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
  type: ClusterIP

```

3. Создаем Ingress для обеспечения доступа снаружи кластера

# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-prod" 
spec:
  rules:
  - host: my-app.example.com  #домен
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
  tls:
  - hosts:
    - my-app.example.com
    secretName: my-app-tls

4. Создаем HPA для автоматического масштабирования

# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

5. Создаем ConfigMap 

# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  nginx.conf: |
    server {
      listen 80;
      server_name localhost;
      location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
      }
    }

6. Развертывание

1) kubectl create namespace my-app
2) kubectl apply -f configmap.yaml -n my-app
3) kubectl apply -f deployment.yaml -n my-app
4) kubectl apply -f service.yaml -n my-app
5) kubectl apply -f ingress.yaml -n my-app
6) kubectl apply -f hpa.yaml -n my-app



# Задание 7

## Условие

Вы получаете сообщение от заказчика: «Проект опять не работает!».
Что будете делать?

## Решение 

1. Уточнение информации

Сначала необходимо собрать базовую информацию:

- какой именно сервис не работает
- с какого времени наблюдается проблема
- какая ошибка отображается у пользователей
- воспроизводится ли проблема у всех пользователей
- что произошло перед тем, как заметили проблему?

2. Проверка мониторинга

Необходимо проверить системы мониторинга:

- состояние серверов
- нагрузку на CPU и память
- использование диска
- состояние сетевых соединений
- наличие алертов

Это позволяет быстро определить возможную причину проблемы.

3. Проверка доступности сервиса

Проверить доступность сервиса:

*curl http://service-url*
*ping server_ip*

4. Проверка состояния сервисов

Проверить, запущены ли необходимые сервисы.

*Например systemctl status docker*
`Если сервис остановлен — попытаться перезапустить его`

5. Анализ логов

Просмотреть логи приложения и инфраструктуры:

*tail -n 100 /var/log/nginx/error.log*

6. Проверка ресурсов

*top*
*free -f*
*df -h*

8. Восстановление сервиса

Для минимизации времени простоя можно:

- перезапустить сервис
- откатить последнее обновление
- переключить трафик на резервный сервер
- временно увеличить ресурсы системы

Если проблему не удается решить самостоятельно, я соберу информацию о текущем состоянии системы, сообщу о проблеме и выполненных действиях своему руководителю или старшему инженеру и передам всю собранную информацию для дальнейшего анализа

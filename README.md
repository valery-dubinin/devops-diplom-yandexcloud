# Дипломный практикум в Yandex.Cloud
  * [Цели:](#цели)
  * [Этапы выполнения:](#этапы-выполнения)
     * [Создание облачной инфраструктуры](#создание-облачной-инфраструктуры)
     * [Создание Kubernetes кластера](#создание-kubernetes-кластера)
     * [Создание тестового приложения](#создание-тестового-приложения)
     * [Подготовка cистемы мониторинга и деплой приложения](#подготовка-cистемы-мониторинга-и-деплой-приложения)
     * [Установка и настройка CI/CD](#установка-и-настройка-cicd)
  * [Что необходимо для сдачи задания?](#что-необходимо-для-сдачи-задания)
  * [Как правильно задавать вопросы дипломному руководителю?](#как-правильно-задавать-вопросы-дипломному-руководителю)

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**

---
## Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
2. Запустить и сконфигурировать Kubernetes кластер.
3. Установить и настроить систему мониторинга.
4. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
5. Настроить CI для автоматической сборки и тестирования.
6. Настроить CD для автоматического развёртывания приложения.

---
## Результат выполнения:

Приложение доступно по адресу: http://app.dubininvk.ru/

Графана доступна по адресу: http://grafana.dubininvk.ru 

Логин - admin

Пароль - prom-operator

Репозиторий с приложением: https://github.com/valery-dubinin/diplom_app

Github Actions: https://github.com/valery-dubinin/diplom_app/actions


---
## Этапы выполнения:


### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://www.terraform.io/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
2. Подготовьте [backend](https://developer.hashicorp.com/terraform/language/backend) для Terraform:  
   а. Рекомендуемый вариант: S3 bucket в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)
3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.
4. Создайте VPC с подсетями в разных зонах доступности.
5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://developer.hashicorp.com/terraform/language/backend) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Решение:

Подготовительная инфраструктура с поднятием сервисного аккаунта и бакета описана тут: [bucket](https://github.com/valery-dubinin/devops-diplom-yandexcloud/tree/main/terraform/bucket)

Получаем бакет для хранения стейт файла:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/00.png)

В результате выполнения для доступа к бакету формируется credfile.key, который потом используется при инициализации основного терраформ кода тут: [providers.tf](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/terraform/providers.tf)

<details>
<summary>shared_credentials_files</summary>

```bash
shared_credentials_files    = ["./credfile.key"]
```
</details>

Бакет создается без проблем: 

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/01.png)

Основной терраформ код применяется без проблем:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/02.png)

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/03.png)

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/) кластер на базе предварительно созданной инфраструктуры.   Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка Kubernetes кластера.  
   а. При помощи Terraform подготовить как минимум 3 виртуальных машины Compute Cloud для создания Kubernetes-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте Terraform для внесения изменений.  
   б. Подготовить [ansible](https://www.ansible.com/) конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
   в. Задеплоить Kubernetes на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи Terraform.
2. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать **региональный** мастер kubernetes с размещением нод в разных 3 подсетях      
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)
  
Ожидаемый результат:

1. Работоспособный Kubernetes кластер.
2. В файле `~/.kube/config` находятся данные для доступа к кластеру.
3. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### Решение:

Для создания кластера пошел по альтерантивному варианту через Yandex Managed Service for Kubernetes.

Код поднимается терраформом. Исходники тут: [Terraform](https://github.com/valery-dubinin/devops-diplom-yandexcloud/tree/main/terraform)

Этим кодом поднимаются сети, сервисный аккаунт для кластера, сам кластер (региональный в 3 зонах доступности) а так же 3 нод-группы машин по одной машине в каждой зоне доступности:

Кластер:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/07.png)

Нод группы:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/08.png)

Сами машины:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/27.png)

Вывод (output) содержит необходимые сведения для подключения к кластеру:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/04.png)

Настраиваем подключение командой: 

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/05.png)

Проверяем подключение:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/06.png)

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение, эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный git репозиторий с простым nginx конфигом, который будет отдавать статические данные.  
   б. Подготовьте Dockerfile для создания образа приложения.  
2. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан Dockerfile.

Ожидаемый результат:

1. Git репозиторий с тестовым приложением и Dockerfile.
2. Регистри с собранным docker image. В качестве регистри может быть DockerHub или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью terraform.

---
### Решение:

Гит репозиторий с приложением находится тут: [diplom_app](https://github.com/valery-dubinin/diplom_app)

Приложение пушится на докерхаб сюда: [dockerhub](https://hub.docker.com/repository/docker/valerydubinin/diplom-app/general)

Результат:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/28.png)

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия Kubernetes кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего Kubernetes кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик Kubernetes.
2. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Способ выполнения:
1. Воспользоваться пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). Альтернативный вариант - использовать набор helm чартов от [bitnami](https://github.com/bitnami/charts/tree/main/bitnami).

2. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте и настройте в кластере [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры. Альтернативный вариант 3 задания: вместо Terraform Cloud или atlantis настройте на автоматический запуск и применение конфигурации terraform из вашего git-репозитория в выбранной вами CI-CD системе при любом комите в main ветку. Предоставьте скриншоты работы пайплайна из CI/CD системы.

Ожидаемый результат:
1. Git репозиторий с конфигурационными файлами для настройки Kubernetes.
2. Http доступ на 80 порту к web интерфейсу grafana.
3. Дашборды в grafana отображающие состояние Kubernetes кластера.
4. Http доступ на 80 порту к тестовому приложению.
5. Atlantis или terraform cloud или ci/cd-terraform

---
### Решение:

Разворачиваем стек мониторинга. Для этого воспользуемся пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)

Создаем пространство имен:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/09.png)

Для доступа по 80 порту к приложению и мониторингу установим ингресс контроллер:

<details>
<summary>Подключаем в helm репозиторий и деплоим чарт с ингресс-контроллером:</summary>

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && \
helm repo update && \
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace=monitoring
```
</details>

Результат:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/10.png)

Затем устанавливаем систему мониторинга:

<details>
<summary>Подключаем в helm репозиторий и деплоим чарт с мониторингом:</summary>

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
helm repo update && \
helm install prometheus prometheus-community/kube-prometheus-stack --namespace=monitoring
```
</details>

Результат:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/11.png)
![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/12.png)

Деплоим приложение:

Для деплоя приложения сначала создадим манифест [deployment.yaml](https://github.com/valery-dubinin/diplom_app/blob/main/deployment/deployment.yaml). Был выбран DaemonSet, т.к. на текущий момент достаточно получения по 1 поду, но на каждой worker ноде.

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/13.png)

Для доступа к приложению деплоим [сервис](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/kuber/service-app.yaml):

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/14.png)

Для внешнего подключения к нашим сервисам настроим DNS на внешний IP адрес нашего инресс-контроллера:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/15.png)

Теперь можно настроить игресс: [ingress.yaml](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/kuber/ingress.yaml)

Поднимаем:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/16.png)

Результаты:

Приложение по адресу: http://app.dubininvk.ru/

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/17.png)

Графана по адресу: http://grafana.dubininvk.ru

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/18.png)

---
### Установка и настройка CI/CD

Осталось настроить ci/cd систему для автоматической сборки docker image и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка docker образа при коммите в репозиторий с тестовым приложением.
2. Автоматический деплой нового docker образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс ci/cd сервиса доступен по http.
2. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр Docker образа.
3. При создании тега (например, v1.0.0) происходит сборка и отправка с соответствующим label в регистри, а также деплой соответствующего Docker образа в кластер Kubernetes.

---
### Решение:

Воспользуемся GitHub Actions.
Для этого нам вначале нужно создать несколько секретов:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/21.png)

DOCKERHUB_TOKEN и DOCKERHUB_USERNAME получаем на докерхабе.

А вот для доступа к kubernates нам необходимо создлать KUBE_CONFOG_DATA со статисческим файлом конфигурации kubectl.

Делаем по инструкции от Yandex.

Для начала создаем сервисный аккаунт в кластере:

kubectl apply -f [sa.yaml](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/kuber/sa.yaml)

<details>
<summary>Вводим ИД кластера</summary>

```bash
CLUSTER_ID=catk17ml3pued0h6brof
```
</details>

<details>
<summary>Пишем сертификат</summary>

```bash
yc managed-kubernetes cluster get --id $CLUSTER_ID --format json | \
  jq -r .master.master_auth.cluster_ca_certificate | \
  awk '{gsub(/\\n/,"\n")}1' > ca.pem
```
</details>

<details>
<summary>Ловим токен сервисного акка</summary>

```bash
SA_TOKEN=$(kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep admin-user-token | awk '{print $1}') -o json | jq -r .data.token | base64 -d)
```
</details>

<details>
<summary>Ловим эндпоинт для подключения</summary>

```bash
MASTER_ENDPOINT=$(yc managed-kubernetes cluster get --id $CLUSTER_ID \
  --format json | \
  jq -r .master.endpoints.external_v4_endpoint)
```
</details>

<details>
<summary>Дополняем файл конфигурации:</summary>

```bash
kubectl config set-cluster sa-test2 \
  --certificate-authority=ca.pem \
  --embed-certs \
  --server=$MASTER_ENDPOINT \
  --kubeconfig=test.kubeconfig
```
</details>

<details>
<summary>Вносим туда токен:</summary>

```bash
kubectl config set-credentials admin-user \
  --token=$SA_TOKEN \
  --kubeconfig=test.kubeconfig
```
</details>

<details>
<summary>Добавляем информацию о контексте в файл конфигурации:</summary>

```bash
kubectl config set-context default \
  --cluster=sa-test2 \
  --user=admin-user \
  --kubeconfig=test.kubeconfig
```
</details>

<details>
<summary>Используем конфиг длядальнейшей работы:</summary>

```bash
kubectl config use-context default \
  --kubeconfig=test.kubeconfig
```
</details>

Конфиг получен!

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/20.png)

<details>
<summary>Теперь кодируем получившийся конфиг:</summary>

```bash
cat test.kubeconfig | base64
```
</details>

И то что получилось вводим в секрет KUBE_CONFOG_DATA

Секреты настроены. Теперь настраиваем [workflow](https://github.com/valery-dubinin/diplom_app/blob/main/.github/workflows/main.yml)

<details>
<summary>Наш workflow:</summary>

```yaml
name: CI/CD Pipeline for diplom-app

on:
  push:
    branches:
      - main
    tags:
      - 'v*'

env:
  IMAGE_TAG: valerydubinin/diplom-app
  RELEASE_NAME: myapp
  NAMESPACE: monitoring

jobs:
  build-and-push:
    name: Build Docker image
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Extract version from tag or commit message
        run: |
          echo "GITHUB_REF: ${GITHUB_REF}"
          if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
            VERSION=${GITHUB_REF#refs/tags/}
          else
            VERSION=$(git log -1 --pretty=format:%B | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
          fi
          if [[ -z "$VERSION" ]]; then
            echo "No version found in the commit message or tag"
            exit 1
          fi
          VERSION=${VERSION//[[:space:]]/}  # Remove any spaces
          echo "Using version: $VERSION"
          echo "VERSION=${VERSION}" >> $GITHUB_ENV

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ env.IMAGE_TAG }}:${{ env.VERSION }}
  
  deploy:
    needs: build-and-push
    name: Deploy to Kubernetes
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/heads/main') || startsWith(github.ref, 'refs/tags/v')
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: List files in the working directory
        run: |
          ls -la

      - name: Set up Kubernetes
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.21.0'

      - name: Extract version from tag or commit message
        run: |
          echo "GITHUB_REF: ${GITHUB_REF}"
          if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
            VERSION=${GITHUB_REF#refs/tags/}
          else
            VERSION=$(git log -1 --pretty=format:%B | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
          fi
          if [[ -z "$VERSION" ]]; then
            echo "No version found in the commit message or tag"
            exit 1
          fi
          VERSION=${VERSION//[[:space:]]/}  # Remove any spaces
          echo "Using version: $VERSION"
          echo "VERSION=${VERSION}" >> $GITHUB_ENV

      - name: Replace image tag in deployment.yaml
        run: |
          if [ ! -f ./deployment/deployment.yaml ]; then
            echo "deployment.yaml not found in the current directory"
            exit 1
          fi
          sed -i "s|image: valerydubinin/diplom-app:.*|image: ${{ env.IMAGE_TAG }}:${{ env.VERSION }}|" ./deployment/deployment.yaml

      - name: Create kubeconfig
        run: |
          mkdir -p $HOME/.kube/

      - name: Authenticate to Kubernetes cluster
        env:
          KUBE_CONFIG_DATA: ${{ secrets.KUBE_CONFIG_DATA }}
        run: |
          echo "${KUBE_CONFIG_DATA}" | base64 --decode > ${HOME}/.kube/config
          kubectl config view
          kubectl get nodes

      - name: Apply Kubernetes manifests
        run: |
          kubectl apply -f ./deployment/deployment.yaml
          kubectl get daemonsets -n monitoring
          kubectl get pods -n monitoring
          kubectl describe daemonset myapp -n monitoring
          kubectl describe service myappsvc -n monitoring
```
</details>

1. На первом этапе мы логинимся в докерхаб с нашими секретами, вырезаем версию приложения из тега или коммита, а затем билдим и пушим приложение в докерхаб с нужной версией.
2. На втором этапе так эе достаем версию из коммита, заменяем тег в deployment.yaml и используя конфигурацию для подключения к калстеру деплоим его. 

Тестируем что получилось:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/23.png)

Деплоится:

![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/24.png)

Работает:
![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/25.png)

GitHub Actions
![img](https://github.com/valery-dubinin/devops-diplom-yandexcloud/blob/main/img/26.png)

---
## Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud или вашего CI-CD-terraform pipeline.
3. Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
5. Репозиторий с конфигурацией Kubernetes кластера.
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)


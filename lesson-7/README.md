# Тема 7 — EKS + ECR (Terraform) + Helm-чарт для Django

Інфраструктура та розгортання Django-застосунку в Amazon EKS.

## Структура

```
lesson-7/
├── main.tf / backend.tf / providers.tf / variables.tf / outputs.tf
├── modules/
│   ├── s3-backend/   # S3-бакет + DynamoDB для стейту Terraform
│   ├── vpc/          # VPC, підмережі, IGW, NAT, теги підмереж для EKS/ELB
│   ├── ecr/          # репозиторій ECR для образу Django
│   └── eks/          # EKS-кластер + node group + IAM-ролі
├── django/           # Django-застосунок + Dockerfile (з теми 4)
└── charts/django-app/ # Helm-чарт: ConfigMap, Secret, Deployment, Service, HPA, Postgres
```

Регіон за замовчуванням — `us-west-2`. Кластер — `lesson-7-eks`, ECR — `lesson-7-ecr`.

## Передумови

- AWS CLI з налаштованими креденшелами (`aws sts get-caller-identity`)
- Terraform ≥ 1.5, kubectl, helm, docker

## 1. Bootstrap S3-бекенду (один раз)

`backend.tf` вказує на бакет, який створює цей самий код, тож спочатку працюємо
з локальним стейтом, а потім мігруємо його в S3:

```bash
cd lesson-7
terraform init                               # локальний стейт
terraform apply -target=module.s3_backend    # створити бакет + таблицю локів
# розкоментувати блок backend "s3" у backend.tf
terraform init -migrate-state                # перенести стейт у S3
```

## 2. Створення інфраструктури

```bash
terraform plan
terraform apply        # VPC + ECR + EKS (EKS підіймається ~15 хв)
```

## 3. Збірка та завантаження образу Django в ECR

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS --password-stdin "${ECR_URL%/*}"

# На звичайній x86-машині:
docker build -t "${ECR_URL}:latest" ./django
docker push "${ECR_URL}:latest"

# На Mac з Apple Silicon (arm64) — збирайте під x86-ноди:
# docker buildx build --platform linux/amd64 -t "${ECR_URL}:latest" --push ./django
```

Далі впишіть значення `$ECR_URL` у `charts/django-app/values.yaml` до `image.repository`.

> Примітка: у `zsh` беріть змінну у фігурні дужки — `"${ECR_URL}:latest"`,
> інакше `:l` тлумачиться як модифікатор і ламає назву образу.

## 4. Підключення kubectl

```bash
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes        # 2 ноди у статусі Ready
```

## 5. Встановлення metrics-server (обов'язково для HPA)

Без нього `kubectl get hpa` показуватиме `<unknown>` замість реального %.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system rollout status deployment/metrics-server
```

## 6. Розгортання чарта

```bash
helm template charts/django-app | kubectl apply --dry-run=client -f -
helm install my-django charts/django-app
```

Чарт піднімає і сам застосунок, і Postgres (`db`) — застосунок з теми 4 очікує
базу за хостом `db`. Вимкнути БД можна через `postgres.enabled=false` у values.

## 7. Перевірка

```bash
kubectl get hpa      # у TARGET реальний % (не <unknown>)
kubectl get pods     # 2+ Django-подів Running (не Pending)
kubectl get svc      # у LoadBalancer є зовнішній адрес (ELB DNS)

# Перевірити доступ через LoadBalancer:
EXTERNAL=$(kubectl get svc my-django-django -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -s -o /dev/null -w "%{http_code}\n" "http://$EXTERNAL/"   # очікується 200
```

## 8. Видалення

Спершу видаліть реліз (це прибере LoadBalancer/ELB), потім інфраструктуру:

```bash
helm uninstall my-django
terraform destroy
```

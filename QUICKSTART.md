# QuickStart - Despliegue en Desarrollo (5 minutos)

## 1. Preparación (Primera vez)

```bash
# Linux/Mac
chmod +x deploy-dev.sh
./deploy-dev.sh

# Windows
deploy-dev.bat
```

El script hace TODO automáticamente:
- ✅ Autentica con GCP
- ✅ Crea buckets de estado
- ✅ Inicializa Terraform
- ✅ Crea VPC, Firewall, Cloud NAT
- ✅ Provisiona GKE cluster
- ✅ Despliega aplicación NestJS
- ✅ Configura kubectl

## 2. Verificar que Funcionó

```bash
# Ver pods corriendo
kubectl get pods

# Ver servicios
kubectl get svc

# Ver logs
kubectl logs -l app.kubernetes.io/name=nestjs-api -f
```

## 3. Acceso a la Aplicación

```bash
# Opción A: Port-forward (acceso local)
kubectl port-forward svc/nestjs-api 3000:80
# Luego: http://localhost:3000

# Opción B: LoadBalancer (acceso externo)
# Ver IP pública
kubectl get svc nestjs-api -o wide
```

## 4. Cambiar Configuración

Editar: `terraform/environments/development/terraform.tfvars`

Después aplicar cambios:

```bash
cd terraform/environments/development
terraform plan
terraform apply
```

## 5. Destruir Environment

```bash
cd terraform/environments/development
terraform destroy -auto-approve
```

---

## Cheat Sheet

| Comando | Descripción |
|---------|-----------|
| `kubectl get pods` | Ver pods |
| `kubectl get svc` | Ver servicios |
| `kubectl logs <POD>` | Ver logs |
| `kubectl exec -it <POD> -- bash` | Entrar a un pod |
| `kubectl port-forward svc/<SERVICE> 3000:80` | Acceso local |
| `kubectl scale deployment <NAME> --replicas=5` | Escalar |
| `kubectl rollout restart deployment/<NAME>` | Reiniciar |
| `kubectl get events` | Ver eventos |
| `terraform plan` | Revisar cambios |
| `terraform apply` | Aplicar cambios |
| `terraform destroy` | Eliminar recursos |

---

## Configuración Rápida

### Variables Principales

```hcl
# terraform/environments/development/terraform.tfvars

gcp_project_id      = "tu-proyecto"
docker_image        = "ghcr.io/tu-org/imagen:latest"
k8s_replicas        = 2
machine_type        = "n1-standard-1"
```

### ConfigMap (Variables de Entorno)

```hcl
config_map_data = {
  "LOG_LEVEL"     = "debug"
  "DATABASE_HOST" = "db.example.com"
}
```

### Secrets (Datos Sensibles)

```hcl
secret_data = {
  "DATABASE_PASSWORD" = "mi-password"
  "JWT_SECRET"        = "mi-jwt"
}
```

---

## Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| Pods en `Pending` | `kubectl describe pod <NAME>` |
| No autenticado GCP | `gcloud auth login` |
| Terraform error | `rm -rf .terraform && terraform init` |
| Acceso denegado | Revisar permisos IAM en GCP |
| Timeout en create | Esperar 10-15 min para GKE |

---

## Costos

- **Desarrollo**: ~$110/mes (n1-standard-1, preemptible)
- **Costo diario**: ~$3.70/día

Para reducir:
- Usar `preemptible=true` (ya está)
- Reducir replicas a 1 cuando no usas
- Auto-scaling activado por defecto

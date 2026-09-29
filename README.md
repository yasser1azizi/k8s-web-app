# Kubernetes DevSecOps Web Application

A security-focused FastAPI application deployed on Kubernetes with container hardening, RBAC, NetworkPolicy, Kyverno policy enforcement, vulnerability scanning, cryptographic image signing, CI/CD security checks, and Prometheus/Grafana monitoring.

The project demonstrates how security controls can be integrated throughout the software delivery lifecycle — from container creation and image scanning to Kubernetes admission control and runtime monitoring.

---

## Architecture

```text
                         Developer
                             │
                             ▼
                       GitHub Repository
                             │
                             ▼
                    GitHub Actions CI/CD
                             │
                 ┌───────────┴───────────┐
                 │                       │
                 ▼                       ▼
          Docker Build              Trivy Scan
                 │
                 ▼
          GitHub Container Registry
                 │
                 ▼
            Cosign Signing
                 │
                 ▼
        Kubernetes / Minikube
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
   Kyverno Policy     RBAC / NetworkPolicy
        │                 │
        └────────┬────────┘
                 ▼
          k8s-web-app Pod
                 │
                 ▼
            FastAPI API
                 │
                 ▼
          Prometheus Metrics
                 │
                 ▼
              Grafana
```

---

# Project Overview

The application is a lightweight FastAPI web service deployed as a single Kubernetes Pod.

The main objective is not the application itself, but the implementation of security and DevOps practices around the application.

The project covers:

- Container security
- Kubernetes security
- Infrastructure configuration
- Image supply-chain security
- Vulnerability management
- CI/CD security
- Policy enforcement
- Monitoring and observability

---

# Technology Stack

| Category | Technology |
|---|---|
| Application | FastAPI / Python |
| Containerization | Docker |
| Orchestration | Kubernetes |
| Local Kubernetes | Minikube |
| Infrastructure | Kubernetes YAML |
| Container Registry | GitHub Container Registry |
| CI/CD | GitHub Actions |
| Vulnerability Scanning | Trivy |
| Image Signing | Cosign |
| Policy Enforcement | Kyverno |
| Monitoring | Prometheus |
| Visualization | Grafana |
| Access Control | Kubernetes RBAC |
| Network Security | Kubernetes NetworkPolicy |
| Operating System | Linux container |
| Source Control | Git / GitHub |

---

# Application

The application is a small FastAPI service exposing a health endpoint.

```text
GET /health
```

Example response:

```json
{
  "status": "healthy"
}
```

The application runs as a dedicated non-root user inside the container.

---

# Container Security

The Docker image is hardened using several security controls.

### Non-root user

The container does not run as root.

```dockerfile
RUN useradd --create-home --uid 1000 appuser

USER appuser
```

Kubernetes additionally enforces:

```yaml
runAsNonRoot: true
runAsUser: 1000
```

This reduces the impact of a potential application compromise.

---

### Read-only filesystem

The Kubernetes container uses:

```yaml
readOnlyRootFilesystem: true
```

This prevents processes inside the container from modifying the container filesystem.

The configuration was verified by attempting to create a file inside the container.

---

### Linux capabilities

All Linux capabilities are dropped:

```yaml
capabilities:
  drop:
    - ALL
```

This follows the principle of least privilege.

---

### Privilege escalation

Privilege escalation is explicitly disabled:

```yaml
allowPrivilegeEscalation: false
```

---

### Seccomp

The Pod uses the Kubernetes RuntimeDefault seccomp profile:

```yaml
seccompProfile:
  type: RuntimeDefault
```

---

# Kubernetes Resource Management

CPU and memory requests and limits are defined for the application.

| Resource | Request | Limit |
|---|---:|---:|
| CPU | 100m | 500m |
| Memory | 128Mi | 256Mi |

This prevents the application from consuming unlimited cluster resources and allows Kubernetes to make informed scheduling decisions.

---

# Configuration Management

Application configuration is separated from the container image.

### ConfigMap

The application uses a Kubernetes ConfigMap for non-sensitive configuration:

```text
APP_ENV=development
LOG_LEVEL=info
```

### Secret

Sensitive configuration is stored in a Kubernetes Secret.

For example:

```text
API_KEY
```

Secrets are not stored directly inside the Docker image or Kubernetes Deployment manifest.

---

# RBAC

The application uses a dedicated Kubernetes ServiceAccount:

```text
k8s-web-app
```

A minimal Role and RoleBinding are used.

The application's permissions are intentionally restricted.

The ServiceAccount can:

```text
get pods
list pods
```

but does not have permission to delete Pods.

This demonstrates the Kubernetes principle of least privilege.

---

# NetworkPolicy

A Kubernetes NetworkPolicy is configured for the application.

The policy controls:

### Ingress

The application accepts TCP traffic on port:

```text
8000
```

### Egress

Outbound traffic is restricted to DNS communication with CoreDNS.

```text
UDP 53
TCP 53
```

> Note: The current Minikube networking setup does not enforce NetworkPolicy at the CNI level. The policy object is therefore configured and documented, but enforcement depends on a NetworkPolicy-capable CNI such as Calico or Cilium.

This distinction is important when evaluating Kubernetes network security.

---

# Kyverno Policy Enforcement

Kyverno is used as a Kubernetes admission policy engine.

The project contains policies that enforce security requirements before workloads are admitted.

For example, Pods that do not specify:

```yaml
runAsNonRoot: true
```

are rejected.

The policy operates in:

```text
Enforce
```

mode.

This moves security checks from documentation into automated Kubernetes policy enforcement.

---

# Container Vulnerability Scanning

Trivy is used to scan the Docker image for vulnerabilities.

The CI pipeline checks:

```text
HIGH
CRITICAL
```

vulnerabilities with available fixes.

The scan is configured with:

```text
--ignore-unfixed
```

This means vulnerabilities without an available fix are not treated as CI failures.

The latest scan completed without HIGH/CRITICAL vulnerabilities with available fixes.

---

# Image Signing with Cosign

Container images are cryptographically signed using Sigstore Cosign.

The workflow is:

```text
Docker Build
     │
     ▼
Trivy Scan
     │
     ▼
Push to GHCR
     │
     ▼
Cosign Sign
     │
     ▼
Kubernetes
```

The image signature is verified using the project's public Cosign key.

The public key is stored in:

```text
cosign.pub
```

The private signing key is never committed to the repository.

---

# Image Digest Pinning

The Kubernetes Deployment does not rely on a mutable image tag such as:

```text
:latest
```

Instead, the deployment references an immutable image digest:

```text
ghcr.io/yasser1azizi/k8s-web-app@sha256:...
```

This ensures that Kubernetes runs the exact image that was verified and signed.

Digest pinning protects against unexpected changes behind mutable tags.

---

# GitHub Container Registry

The container image is stored in GitHub Container Registry:

```text
ghcr.io/yasser1azizi/k8s-web-app
```

The registry package is private.

Kubernetes authenticates against GHCR using an image pull secret.

---

# CI/CD Security Pipeline

GitHub Actions automatically performs security checks when changes are pushed or pull requests are created.

The pipeline includes:

```text
Checkout
   │
   ▼
Docker Build
   │
   ▼
Trivy Vulnerability Scan
   │
   ▼
Push Image
   │
   ▼
Cosign Sign
   │
   ▼
Cosign Verify
```

A vulnerability scan failure prevents the pipeline from continuing.

This provides an automated security gate before the container image is released.

---

# Monitoring and Observability

Prometheus and Grafana are used to monitor the Kubernetes environment.

The monitoring stack contains:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter
- Prometheus Operator

Grafana provides visibility into Kubernetes workloads and application resource consumption.

The application can be monitored for metrics such as:

- CPU usage
- Memory usage
- CPU requests and limits
- Memory requests and limits
- Pod status
- Kubernetes resource information

---

# Security Architecture

The project implements multiple independent security layers.

```text
                    Application
                        │
                        ▼
                 FastAPI Container
                        │
             ┌──────────┴──────────┐
             │                     │
        Non-root user        Read-only FS
             │                     │
             ├──────────┬──────────┤
             │          │          │
             ▼          ▼          ▼
          Seccomp    Drop ALL    No Privilege
                       Caps       Escalation
             │
             ▼
          Kubernetes
             │
     ┌───────┼────────┐
     │       │        │
     ▼       ▼        ▼
    RBAC  Network   Kyverno
          Policy    Policies
     │       │        │
     └───────┼────────┘
             ▼
       Image Security
             │
       ┌─────┴─────┐
       │           │
       ▼           ▼
     Trivy       Cosign
       │           │
       └─────┬─────┘
             ▼
          CI/CD
             │
             ▼
        Monitoring
             │
       ┌─────┴─────┐
       ▼           ▼
  Prometheus    Grafana
```

---

# Verification

Security controls were tested rather than only configured.

Examples include:

### Verify non-root execution

```bash
kubectl exec deploy/k8s-web-app -- id
```

Expected result:

```text
uid=1000(appuser)
```

### Verify read-only filesystem

```bash
kubectl exec deploy/k8s-web-app -- touch /test-file
```

Expected result:

```text
Read-only file system
```

### Verify RBAC

The application ServiceAccount can read Pods but cannot delete them.

### Verify image digest

```bash
kubectl describe pod <pod-name>
```

The running container shows the expected immutable image digest.

### Verify Kyverno

A workload that violates the configured security policy is rejected by the Kubernetes admission controller.

### Verify Cosign

The deployed container image can be verified using the project's public Cosign key.

---

# Project Structure

```text
k8s-web-app/
│
├── app/
│   └── main.py
│
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── role.yaml
│   ├── rolebinding.yaml
│   ├── network-policy.yaml
│   ├── verify-image-signature.yaml
│   └── ...
│
├── .github/
│   └── workflows/
│       └── security-pipeline.yaml
│
├── Dockerfile
├── requirements.txt
├── cosign.pub
└── README.md
```

---

# Key DevSecOps Principles Demonstrated

This project demonstrates practical implementation of:

- **Least privilege**
- **Defense in depth**
- **Immutable infrastructure**
- **Container hardening**
- **Kubernetes security**
- **Policy as code**
- **Software supply-chain security**
- **Automated vulnerability scanning**
- **Cryptographic image signing**
- **CI/CD security gates**
- **Observability and monitoring**

---

# Lessons Learned

During the project, several practical Kubernetes security concepts became particularly important:

### Security configuration is not the same as enforcement

A NetworkPolicy can exist in Kubernetes without actually filtering traffic if the underlying CNI does not support NetworkPolicy enforcement.

### Image tags are mutable

Using:

```text
image: ...:latest
```

does not guarantee that the same image will be deployed every time.

Using an immutable digest provides stronger supply-chain guarantees.

### Security should be automated

Kyverno, Trivy, Cosign and GitHub Actions turn security requirements into automated controls instead of relying only on manual checks.

### Kubernetes security is layered

No single security control is sufficient. Container hardening, RBAC, network controls, admission policies, image security and monitoring provide complementary layers.

---

# Future Improvements

Possible future extensions include:

- Deploying the application on a NetworkPolicy-capable CNI such as Cilium or Calico
- Signing images directly by immutable digest in CI/CD
- Adding Prometheus alerting rules
- Adding Grafana application-specific dashboards
- Integrating SBOM generation
- Adding image provenance / SLSA-style attestations
- Adding automated Kubernetes manifest scanning
- Deploying the application to a managed Kubernetes platform such as Azure Kubernetes Service

---

# Conclusion

This project demonstrates a complete DevSecOps workflow around a containerized Kubernetes application.

The focus is on integrating security into the entire lifecycle:

```text
Code
 ↓
Container
 ↓
Vulnerability Scan
 ↓
Image Signing
 ↓
Private Registry
 ↓
Kubernetes
 ↓
Admission Policies
 ↓
Runtime Security
 ↓
Monitoring
```

The result is a small but security-focused Kubernetes environment that demonstrates practical experience with Docker, Kubernetes, CI/CD, cloud-native security, container supply-chain security, policy enforcement and observability.
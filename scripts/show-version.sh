#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# show-version.sh
# Run inside or outside the cluster to display the current Odoo version.
# Usage: ./show-version.sh [namespace]
# ─────────────────────────────────────────────────────────────────────────────

NS="${1:-odoo}"
DEPLOY="odoo-deployment"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║           Odoo Kubernetes Version Info           ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Current image tag
IMAGE=$(kubectl get deployment/${DEPLOY} -n ${NS} \
    -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
echo "  Deployment image : ${IMAGE}"

# App version from annotation
APP_VER=$(kubectl get deployment/${DEPLOY} -n ${NS} \
    -o jsonpath='{.metadata.annotations.app\.version}' 2>/dev/null)
echo "  App version      : ${APP_VER}"

# Build number
BUILD=$(kubectl get deployment/${DEPLOY} -n ${NS} \
    -o jsonpath='{.metadata.annotations.build\.number}' 2>/dev/null)
echo "  Build number     : ${BUILD}"

echo ""
echo "  ── Pods ──────────────────────────────────────────"
kubectl get pods -n ${NS} -l app=odoo \
    -o custom-columns=\
'POD:.metadata.name,STATUS:.status.phase,VERSION:.metadata.labels.version,READY:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image'

echo ""
echo "  ── Version env inside each pod ───────────────────"
for POD in $(kubectl get pods -n ${NS} -l app=odoo -o jsonpath='{.items[*].metadata.name}'); do
    VER=$(kubectl exec ${POD} -n ${NS} -- printenv APP_VERSION 2>/dev/null)
    echo "  ${POD}  →  ${VER}"
done

echo ""

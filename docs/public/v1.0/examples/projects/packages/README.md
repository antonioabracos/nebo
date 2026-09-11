# Exact local package workspace

Run neboc package freeze workspace.json --store ./store. Compute the SHA-256 of store/nebo.lock.json independently. Run neboc package build --store ./store --lock ./store/nebo.lock.json --lock-sha256 DIGEST --output ./consumer. Execute consumer/bin/program: process status 108 = 61 + 47. Use an empty output directory. No external registry or network is used.

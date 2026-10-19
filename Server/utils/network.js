const os = require('os');

/**
 * Automatically discovers the local LAN IPv4 address of this machine.
 * Prioritizes Wi-Fi / Ethernet non-internal interfaces.
 */
function getLocalIpAddress() {
    if (process.env.PUBLIC_HOST && process.env.PUBLIC_HOST.trim()) {
        return process.env.PUBLIC_HOST.trim();
    }

    const interfaces = os.networkInterfaces();
    const candidates = [];

    for (const [name, addrs] of Object.entries(interfaces)) {
        if (!addrs) continue;
        for (const iface of addrs) {
            // Only examine IPv4 non-internal addresses
            if (iface.family === 'IPv4' && !iface.internal) {
                const isPreferred = /^(wl|eth|en)/i.test(name);
                candidates.push({
                    name,
                    address: iface.address,
                    isPreferred,
                });
            }
        }
    }

    // Prefer physical Wi-Fi or Ethernet interface
    const preferred = candidates.find((c) => c.isPreferred);
    if (preferred) return preferred.address;
    if (candidates.length > 0) return candidates[0].address;

    return '127.0.0.1';
}

/**
 * Returns dynamic base URL for local LAN access
 */
function getNetworkBaseUrl(port = 5000) {
    const ip = getLocalIpAddress();
    return `http://${ip}:${port}`;
}

module.exports = {
    getLocalIpAddress,
    getNetworkBaseUrl,
};

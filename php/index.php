<?php

declare(strict_types=1);

/**
 * PHP API Stack - Demo Landing Page
 * 
 * This file serves as a fallback demonstration page when no application is mounted.
 * It validates all stack components and provides useful information for developers.
 * 
 * @package KaririCode\PhpApiStack
 * @version 1.2.1
 * @license MIT
 */

namespace KaririCode\PhpApiStack\Demo;

// Security: Prevent direct access in production environments
if (getenv('APP_ENV') === 'production' && !getenv('DEMO_MODE')) {
    http_response_code(404);
    exit('Not Found Walmir');
}

/**
 * Component Status Check Interface
 */
interface ComponentCheckInterface
{
    public function getName(): string;
    public function check(): StatusResult;
}

/**
 * Immutable Status Result Value Object
 */
final readonly class StatusResult
{
    public function __construct(
        public bool $healthy,
        public string $message,
        public array $details = []
    ) {}
}

/**
 * Abstract Base Checker (Template Method Pattern)
 */
abstract class AbstractComponentCheck implements ComponentCheckInterface
{
    abstract protected function performCheck(): StatusResult;

    public function check(): StatusResult
    {
        try {
            return $this->performCheck();
        } catch (\Throwable $e) {
            return new StatusResult(
                healthy: false,
                message: 'Error: ' . $e->getMessage(),
                details: []
            );
        }
    }
}

/**
 * PHP Runtime Check
 */
final class PhpCheck extends AbstractComponentCheck
{
    public function getName(): string
    {
        return 'PHP';
    }

    protected function performCheck(): StatusResult
    {
        $version = PHP_VERSION;
        $extensions = get_loaded_extensions();

        return new StatusResult(
            healthy: true,
            message: "PHP {$version} with " . count($extensions) . " extensions",
            details: [
                'version' => $version,
                'sapi' => PHP_SAPI,
                'extensions_count' => count($extensions),
                'memory_limit' => ini_get('memory_limit'),
                'max_execution_time' => ini_get('max_execution_time') . 's',
            ]
        );
    }
}

/**
 * OPcache Check
 */
final class OpcacheCheck extends AbstractComponentCheck
{
    public function getName(): string
    {
        return 'OPcache';
    }

    protected function performCheck(): StatusResult
    {
        if (!function_exists('opcache_get_status')) {
            return new StatusResult(
                healthy: false,
                message: 'OPcache extension not available',
                details: []
            );
        }

        $status = @opcache_get_status(false);

        if ($status === false) {
            return new StatusResult(
                healthy: false,
                message: 'OPcache is disabled',
                details: []
            );
        }

        $memoryUsed = $status['memory_usage']['used_memory'] ?? 0;
        $memoryFree = $status['memory_usage']['free_memory'] ?? 0;
        $memoryTotal = $memoryUsed + $memoryFree;
        $usagePercent = $memoryTotal > 0 ? round(($memoryUsed / $memoryTotal) * 100, 1) : 0;

        return new StatusResult(
            healthy: true,
            message: "OPcache enabled ({$usagePercent}% memory used)",
            details: [
                'memory_used' => $this->formatBytes($memoryUsed),
                'cached_scripts' => $status['opcache_statistics']['num_cached_scripts'] ?? 0,
                'jit_enabled' => ($status['jit']['enabled'] ?? false) ? 'Yes' : 'No',
            ]
        );
    }

    private function formatBytes(int $bytes): string
    {
        $units = ['B', 'KB', 'MB', 'GB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= (1 << (10 * $pow));
        return round($bytes, 2) . ' ' . $units[$pow];
    }
}

/**
 * Redis Connectivity Check
 */
final class RedisCheck extends AbstractComponentCheck
{
    public function getName(): string
    {
        return 'Redis';
    }


    /**
     * Smart Redis Host Resolution
     * 
     * Tenta resolver o hostname. Se falhar, usa 127.0.0.1 (standalone mode).
     */
    protected function getRedisHost(): string
    {
        $host = getenv('REDIS_HOST') ?: '127.0.0.1';

        // Se for "redis" (docker-compose), verifica se resolve
        if ($host === 'redis') {
            // Suprime warning de DNS
            $resolved = @gethostbyname($host);

            // Se não resolveu (retorna o próprio hostname), usa localhost
            if ($resolved === $host) {
                return '127.0.0.1';
            }
        }

        return $host;
    }


    protected function performCheck(): StatusResult
    {
        if (!extension_loaded('redis')) {
            return new StatusResult(
                healthy: false,
                message: 'Redis extension not installed',
                details: []
            );
        }

        $redis = new \Redis();

        $host = $this->getRedisHost();
        $password = getenv('REDIS_PASSWORD') ?: null;
        $port = 6379;

        try {
            $connected = @$redis->connect($host, $port, 1.0);

            if (!$connected) {
                return new StatusResult(
                    healthy: false,
                    message: 'Cannot connect to Redis server',
                    details: []
                );
            }


            if ($password !== null && $password !== '') {
                if (!@$redis->auth($password)) {
                    return new StatusResult(
                        healthy: false,
                        message: 'Redis authentication failed (NOAUTH). Check REDIS_PASSWORD.',
                        details: ['host' => $host]
                    );
                }
            }


            $pong = $redis->ping();

            if ($pong !== true && $pong !== '+PONG') {
                return new StatusResult(
                    healthy: false,
                    message: 'Redis ping failed',
                    details: []
                );
            }

            $info = $redis->info();

            return new StatusResult(
                healthy: true,
                message: 'Redis ' . ($info['redis_version'] ?? 'unknown') . ' connected',
                details: [
                    'version' => $info['redis_version'] ?? 'unknown',
                    'uptime' => $this->formatUptime((int)($info['uptime_in_seconds'] ?? 0)),
                    'memory' => $info['used_memory_human'] ?? 'unknown',
                ]
            );
        } catch (\Throwable $e) {
            return new StatusResult(
                healthy: false,
                message: 'Redis error: ' . $e->getMessage(),
                details: []
            );
        } finally {
            @$redis->close();
        }
    }

    private function formatUptime(int $seconds): string
    {
        if ($seconds < 60) return "{$seconds}s";
        if ($seconds < 3600) return floor($seconds / 60) . "m";
        if ($seconds < 86400) return floor($seconds / 3600) . "h";
        return floor($seconds / 86400) . "d";
    }
}

/**
 * Status Dashboard (Facade Pattern)
 */
final class StatusDashboard
{
    /** @var ComponentCheckInterface[] */
    private array $checks = [];

    public function addCheck(ComponentCheckInterface $check): self
    {
        $this->checks[] = $check;
        return $this;
    }

    public function runAll(): array
    {
        $results = [];
        $allHealthy = true;

        foreach ($this->checks as $check) {
            $result = $check->check();
            $results[$check->getName()] = $result;

            if (!$result->healthy) {
                $allHealthy = false;
            }
        }

        return [
            'overall_healthy' => $allHealthy,
            'checks' => $results,
        ];
    }
}

// Run status checks
$dashboard = new StatusDashboard();
$dashboard
    ->addCheck(new PhpCheck())
    ->addCheck(new OpcacheCheck())
    ->addCheck(new RedisCheck());

$status = $dashboard->runAll();

// Collect system information
$stackInfo = [
    'image' => 'kariricode/php-api-stack',
    'version' => getenv('STACK_VERSION') ?: '1.2.1',
    'php_version' => PHP_VERSION,
    'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'nginx',
    'document_root' => $_SERVER['DOCUMENT_ROOT'] ?? '/var/www/html/public',
];

?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP API Stack - Ready for Development</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            color: #333;
        }

        .container {
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 900px;
            width: 100%;
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            font-weight: 700;
        }

        .header p {
            font-size: 1.1rem;
            opacity: 0.95;
        }

        .badge {
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-top: 15px;
            backdrop-filter: blur(10px);
        }

        .content {
            padding: 40px;
        }

        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .status-card {
            background: #f8f9fa;
            border-radius: 12px;
            padding: 24px;
            border-left: 4px solid #667eea;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .status-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
        }

        .status-card.healthy {
            border-left-color: #10b981;
        }

        .status-card.unhealthy {
            border-left-color: #ef4444;
        }

        .status-card h3 {
            font-size: 1.1rem;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .status-icon {
            width: 20px;
            height: 20px;
            border-radius: 50%;
        }

        .status-icon.healthy {
            background: #10b981;
        }

        .status-icon.unhealthy {
            background: #ef4444;
        }

        .status-message {
            color: #666;
            font-size: 0.95rem;
            margin-bottom: 12px;
        }

        .status-details {
            font-size: 0.85rem;
            color: #888;
            line-height: 1.6;
        }

        .info-section {
            background: #f8f9fa;
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 20px;
        }

        .info-section h2 {
            font-size: 1.3rem;
            margin-bottom: 16px;
            color: #667eea;
        }

        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
        }

        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #e5e7eb;
        }

        .info-label {
            font-weight: 600;
            color: #666;
        }

        .info-value {
            color: #333;
            font-family: 'Courier New', monospace;
        }

        .alert {
            background: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        .alert h3 {
            color: #92400e;
            margin-bottom: 8px;
            font-size: 1.1rem;
        }

        .alert p {
            color: #78350f;
            line-height: 1.6;
        }

        .quick-links {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 12px;
            margin-top: 20px;
        }

        .quick-link {
            display: block;
            background: white;
            padding: 16px;
            border-radius: 8px;
            text-decoration: none;
            color: #667eea;
            border: 2px solid #667eea;
            text-align: center;
            font-weight: 600;
            transition: all 0.2s;
        }

        .quick-link:hover {
            background: #667eea;
            color: white;
            transform: translateY(-2px);
        }

        .footer {
            text-align: center;
            padding: 20px;
            color: #888;
            font-size: 0.9rem;
            border-top: 1px solid #e5e7eb;
        }

        .footer a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }

        .footer a:hover {
            text-decoration: underline;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <h1>🚀 PHP API Stack</h1>
            <p>Production-ready development environment</p>
            <span class="badge">Version <?= htmlspecialchars($stackInfo['version']) ?></span>
        </div>

        <div class="content">
            <div class="alert">
                <h3>⚠️ Demo Mode Active</h3>
                <p>
                    This is a placeholder page shown when no application is mounted.
                    Mount your Symfony/Laravel project to <code><?= htmlspecialchars($stackInfo['document_root']) ?></code>
                    to replace this demo page with your application.
                </p>
            </div>

            <h2 style="margin-bottom: 20px; color: #333;">Component Status</h2>

            <div class="status-grid">
                <?php foreach ($status['checks'] as $name => $result): ?>
                    <div class="status-card <?= $result->healthy ? 'healthy' : 'unhealthy' ?>">
                        <h3>
                            <span class="status-icon <?= $result->healthy ? 'healthy' : 'unhealthy' ?>"></span>
                            <?= htmlspecialchars($name) ?>
                        </h3>
                        <div class="status-message">
                            <?= htmlspecialchars($result->message) ?>
                        </div>
                        <?php if (!empty($result->details)): ?>
                            <div class="status-details">
                                <?php foreach ($result->details as $key => $value): ?>
                                    <div><?= htmlspecialchars(ucfirst(str_replace('_', ' ', $key))) ?>: <strong><?= htmlspecialchars((string)$value) ?></strong></div>
                                <?php endforeach; ?>
                            </div>
                        <?php endif; ?>
                    </div>
                <?php endforeach; ?>
            </div>

            <div class="info-section">
                <h2>Stack Information</h2>
                <div class="info-grid">
                    <div class="info-item">
                        <span class="info-label">Docker Image:</span>
                        <span class="info-value"><?= htmlspecialchars($stackInfo['image']) ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Stack Version:</span>
                        <span class="info-value"><?= htmlspecialchars($stackInfo['version']) ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">PHP Version:</span>
                        <span class="info-value"><?= htmlspecialchars($stackInfo['php_version']) ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Web Server:</span>
                        <span class="info-value"><?= htmlspecialchars($stackInfo['server_software']) ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Document Root:</span>
                        <span class="info-value"><?= htmlspecialchars($stackInfo['document_root']) ?></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Overall Status:</span>
                        <span class="info-value" style="color: <?= $status['overall_healthy'] ? '#10b981' : '#ef4444' ?>">
                            <?= $status['overall_healthy'] ? '✓ Healthy' : '✗ Issues Detected' ?>
                        </span>
                    </div>
                </div>
            </div>

            <div class="info-section">
                <h2>Quick Links</h2>
                <div class="quick-links">
                    <a href="/health.php" class="quick-link">Health Check</a>
                    <a href="https://github.com/kariricode/php-api-stack" class="quick-link" target="_blank">Documentation</a>
                    <a href="https://hub.docker.com/r/kariricode/php-api-stack" class="quick-link" target="_blank">Docker Hub</a>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>
                Built with ❤️ by <a href="https://github.com/kariricode" target="_blank">KaririCode</a> |
                <a href="https://github.com/kariricode/php-api-stack/issues" target="_blank">Report Issue</a>
            </p>
        </div>
    </div>
</body>

</html>
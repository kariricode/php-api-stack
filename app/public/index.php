<?php

/**
 * PHP API Stack - Default Application
 * 
 * This is the default application served by dtihubmaker/php-api-stack
 * Replace this with your Symfony application
 */

// Set JSON response header
header('Content-Type: application/json');
header('X-Powered-By: PHP API Stack');

// Enable CORS for API access
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Get request info
$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['REQUEST_URI'];
$query = $_SERVER['QUERY_STRING'] ?? '';

// Stack information
$stackInfo = [
    'name' => 'PHP API Stack',
    'image' => 'dtihubmaker/php-api-stack',
    'version' => '1.0.0',
    'environment' => $_ENV['APP_ENV'] ?? 'production',
];

// PHP information
$phpInfo = [
    'version' => PHP_VERSION,
    'sapi' => PHP_SAPI,
    'memory_limit' => ini_get('memory_limit'),
    'max_execution_time' => ini_get('max_execution_time'),
    'upload_max_filesize' => ini_get('upload_max_filesize'),
    'post_max_size' => ini_get('post_max_size'),
    'date_timezone' => date_default_timezone_get(),
];

// Extensions check
$extensions = [
    'core' => [
        'pdo' => extension_loaded('pdo'),
        'pdo_mysql' => extension_loaded('pdo_mysql'),
        'pdo_pgsql' => extension_loaded('pdo_pgsql'),
        'redis' => extension_loaded('redis'),
        'opcache' => extension_loaded('Zend OPcache'),
        'intl' => extension_loaded('intl'),
        'zip' => extension_loaded('zip'),
        'gd' => extension_loaded('gd'),
        'mbstring' => extension_loaded('mbstring'),
        'xml' => extension_loaded('xml'),
        'curl' => extension_loaded('curl'),
    ],
    'pecl' => [
        'apcu' => extension_loaded('apcu'),
        'uuid' => extension_loaded('uuid'),
        'xdebug' => extension_loaded('xdebug'),
    ]
];

// OPcache status
$opcacheStatus = [];
if (function_exists('opcache_get_status')) {
    $status = opcache_get_status(false);
    if ($status) {
        $opcacheStatus = [
            'enabled' => $status['opcache_enabled'] ?? false,
            'memory_usage' => [
                'used' => $status['memory_usage']['used_memory'] ?? 0,
                'free' => $status['memory_usage']['free_memory'] ?? 0,
                'percentage' => $status['memory_usage']['current_wasted_percentage'] ?? 0,
            ],
            'statistics' => [
                'hits' => $status['opcache_statistics']['hits'] ?? 0,
                'misses' => $status['opcache_statistics']['misses'] ?? 0,
                'cached_scripts' => $status['opcache_statistics']['num_cached_scripts'] ?? 0,
            ],
            'jit' => [
                'enabled' => $status['jit']['enabled'] ?? false,
                'on' => $status['jit']['on'] ?? false,
                'buffer_size' => $status['jit']['buffer_size'] ?? 0,
            ]
        ];
    }
}

// Redis check
$redisStatus = [];
try {
    if (extension_loaded('redis')) {
        $redis = new Redis();
        $redis->connect('127.0.0.1', 6379);
        $redisInfo = $redis->info();
        $redisStatus = [
            'connected' => true,
            'version' => $redisInfo['redis_version'] ?? 'unknown',
            'used_memory' => $redisInfo['used_memory_human'] ?? 'unknown',
            'connected_clients' => $redisInfo['connected_clients'] ?? 0,
            'total_commands_processed' => $redisInfo['total_commands_processed'] ?? 0,
        ];
        $redis->close();
    }
} catch (Exception $e) {
    $redisStatus = [
        'connected' => false,
        'error' => $e->getMessage()
    ];
}

// Symfony CLI check
$symfonyVersion = 'Not installed';
if (file_exists('/usr/local/bin/symfony')) {
    $symfonyVersion = trim(shell_exec('symfony version --no-ansi 2>/dev/null | grep "Symfony CLI" | cut -d" " -f3'));
}

// Composer check
$composerVersion = 'Not installed';
if (file_exists('/usr/local/bin/composer')) {
    $composerVersion = trim(shell_exec('composer --version --no-ansi 2>/dev/null | cut -d" " -f3'));
}

// Server information
$serverInfo = [
    'software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
    'hostname' => gethostname(),
    'ip' => $_SERVER['SERVER_ADDR'] ?? 'Unknown',
    'port' => $_SERVER['SERVER_PORT'] ?? 80,
    'protocol' => $_SERVER['SERVER_PROTOCOL'] ?? 'HTTP/1.1',
];

// Routes (simple routing example)
$routes = [
    '/' => function () use ($stackInfo, $phpInfo, $extensions, $opcacheStatus, $redisStatus, $symfonyVersion, $composerVersion, $serverInfo) {
        return [
            'status' => 'success',
            'message' => 'PHP API Stack is running!',
            'stack' => $stackInfo,
            'php' => $phpInfo,
            'extensions' => $extensions,
            'opcache' => $opcacheStatus,
            'redis' => $redisStatus,
            'symfony_cli' => $symfonyVersion,
            'composer' => $composerVersion,
            'server' => $serverInfo,
            'timestamp' => date('c'),
            'endpoints' => [
                '/' => 'This info page',
                '/health' => 'Health check endpoint',
                '/info' => 'PHP info (development only)',
                '/status' => 'Detailed status',
            ]
        ];
    },
    '/health' => function () {
        return [
            'status' => 'healthy',
            'timestamp' => date('c')
        ];
    },
    '/status' => function () use ($opcacheStatus, $redisStatus) {
        return [
            'status' => 'ok',
            'services' => [
                'nginx' => true,
                'php' => true,
                'redis' => $redisStatus['connected'] ?? false,
                'opcache' => $opcacheStatus['enabled'] ?? false,
            ],
            'timestamp' => date('c')
        ];
    },
    '/info' => function () {
        if (($_ENV['APP_ENV'] ?? 'production') !== 'production') {
            ob_start();
            phpinfo();
            $info = ob_get_clean();
            header('Content-Type: text/html');
            echo $info;
            exit;
        }
        return ['error' => 'PHPInfo is disabled in production'];
    }
];

// Parse path without query string
$cleanPath = parse_url($path, PHP_URL_PATH);

// Route handling
if (isset($routes[$cleanPath])) {
    $response = $routes[$cleanPath]();
    if (!is_array($response)) {
        exit; // For HTML responses like phpinfo
    }
} else {
    http_response_code(404);
    $response = [
        'error' => 'Not Found',
        'path' => $cleanPath,
        'available_endpoints' => array_keys($routes)
    ];
}

// Output JSON response
echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);

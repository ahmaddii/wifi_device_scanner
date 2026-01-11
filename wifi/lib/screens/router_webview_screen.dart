import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/device_model.dart';

/// WebView screen for router admin panel
/// Loads router's web interface for manual device blocking
/// 
/// IMPORTANT NOTES:
/// - App does NOT auto-login (would require router credentials)
/// - App does NOT auto-block devices (requires router API access)
/// - User must login manually using router admin credentials
/// - User must navigate to MAC filtering/blocking section manually
/// 
/// This is the ONLY Play Store compliant approach
class RouterWebViewScreen extends StatefulWidget {
  final String routerIp;
  final DeviceModel targetDevice;

  const RouterWebViewScreen({
    super.key,
    required this.routerIp,
    required this.targetDevice,
  });

  @override
  State<RouterWebViewScreen> createState() => _RouterWebViewScreenState();
}

class _RouterWebViewScreenState extends State<RouterWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Initialize WebView controller
  void _initializeWebView() {
    // Build router URL (try both http and https)
    final routerUrl = 'http://${widget.routerIp}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _loadError = null;
            });
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _loadError = error.description;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(routerUrl));
  }

  /// Reload page
  void _reload() {
    _controller.reload();
    setState(() {
      _loadError = null;
    });
  }

  /// Go back in WebView history
  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else {
      // If can't go back, exit screen
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Show device info dialog
  void _showDeviceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device to Block'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('IP Address', widget.targetDevice.ipAddress),
            const SizedBox(height: 8),
            _buildInfoRow('MAC Address', 
                widget.targetDevice.macAddress ?? 'Not available'),
            const SizedBox(height: 8),
            _buildInfoRow('Vendor', 
                widget.targetDevice.vendor ?? 'Unknown'),
            const SizedBox(height: 16),
            const Text(
              'To block this device:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Login to your router\n'
              '2. Find MAC filtering/blocking\n'
              '3. Add the MAC address above\n'
              '4. Save settings',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Router Admin Panel'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDeviceInfo,
            tooltip: 'Device Info',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView
          if (_loadError == null)
            WebViewWidget(controller: _controller),

          // Error Message
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load router page',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Possible reasons:\n'
                      '• Router not accessible\n'
                      '• Wrong IP address\n'
                      '• Router uses HTTPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading Progress Bar
          if (_isLoading && _loadError == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.info, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Login with router admin credentials',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Default: admin/admin or admin/password',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
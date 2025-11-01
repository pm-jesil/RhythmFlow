import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/theme_extension.dart';

class CustomWebView extends StatefulWidget {
  final String url;
  final String title;

  const CustomWebView({
    super.key,
    required this.url,
    this.title = 'About Us',
  });

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
              if (progress == 100) {
                _isLoading = false;
                _hasError = false;
              }
            });
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _loadingProgress = 0;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = false;
                _loadingProgress = 100;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description.isNotEmpty
                    ? error.description
                    : 'Unable to load the webpage. Please check your internet connection.';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        _loadingProgress = 0;
      });
      _webViewController.reload();
    }
  }

  @override
  void dispose() {
    // WebViewController doesn't need explicit disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.title,
        style: TextStyle(
          color: context.onSurfaceColor,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      backgroundColor: context.backgroundColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: context.onSurfaceColor,
          size: 20.sp,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            CupertinoIcons.arrow_clockwise,
            color: context.onSurfaceColor,
            size: 20.sp,
          ),
          onPressed: _reload,
          tooltip: 'Reload',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        // WebView
        AnimatedOpacity(
          opacity: _hasError ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: WebViewWidget(controller: _webViewController),
        ),
        // Loading Indicator with smooth fade
        if (_isLoading)
          AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _buildLoadingIndicator(),
          ),
        // Error View with smooth fade
        if (_hasError)
          AnimatedOpacity(
            opacity: _hasError ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildErrorView(),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: context.backgroundColor,
      child: Column(
        children: [
          // Progress bar at top
          if (_loadingProgress > 0 && _loadingProgress < 100)
            LinearProgressIndicator(
              value: _loadingProgress / 100,
              backgroundColor: context.onSurfaceVariantColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(context.primaryStart),
              minHeight: 3.h,
            ),
          // Loading spinner
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _loadingProgress > 0 && _loadingProgress < 100
                        ? _loadingProgress / 100
                        : null,
                    valueColor: AlwaysStoppedAnimation<Color>(context.primaryStart),
                    strokeWidth: 3.w,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _loadingProgress > 0 && _loadingProgress < 100
                        ? 'Loading... $_loadingProgress%'
                        : 'Loading...',
                    style: TextStyle(
                      color: context.onSurfaceVariantColor,
                      fontSize: 14.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: context.backgroundColor,
      padding: EdgeInsets.all(24.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64.sp,
              color: context.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to Load',
              style: TextStyle(
                color: context.onSurfaceColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Unable to load the webpage',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.onSurfaceVariantColor,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: Icon(
                CupertinoIcons.arrow_clockwise,
                size: 18.sp,
              ),
              label: Text(
                'Retry',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryStart,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


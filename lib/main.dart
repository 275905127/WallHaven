import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 确保你的目录下有 pages 文件夹，并且里面有 home_page.dart
import 'pages/home_page.dart'; 

void main() {
  // 设置沉浸式状态栏（透明背景，黑色图标）
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 顶部状态栏透明
    statusBarIconBrightness: Brightness.dark, // 顶部图标变黑
    systemNavigationBarColor: Colors.transparent, // 底部导航栏透明
    systemNavigationBarIconBrightness: Brightness.dark, // 底部图标变黑
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 去掉右上角那个 debug 标签
      title: 'Wallhaven',
      
      // ====================================================
      // 全局主题配置 (复刻 CheckFirm 风格)
      // ====================================================
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        
        // 核心背景色：温暖的浅灰色 (精准吸色结果)
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        
        // 颜色方案
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // 全局主色调为蓝色
          background: const Color(0xFFF2F2F2), // 背景一致
          surface: Colors.white, // 卡片表面为纯白
        ),

        // 顶部导航栏主题 (统一去掉阴影，背景与页面融合)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F2F2), 
          elevation: 0,
          scrolledUnderElevation: 0, // 滚动时不要改变颜色
          centerTitle: false, // 标题靠左
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 24, // 大标题字号
            fontWeight: FontWeight.bold, // 加粗
            fontFamily: 'Roboto', 
          ),
          iconTheme: IconThemeData(color: Colors.black), // 图标黑色
        ),

        // 开关组件主题 (全局蓝色风格)
        switchTheme: SwitchThemeData(
          // 选中时的轨道颜色：蓝色
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.blue;
            }
            return null;
          }),
          // 选中时的滑块颜色：白色
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return null;
          }),
        ),
      ),
      
      // 启动页指向 HomePage
      home: const HomePage(),
    );
  }
}

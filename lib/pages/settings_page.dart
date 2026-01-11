  Widget _buildBottomDialog(BuildContext context, {
    required String title,
    required Widget content,
    required VoidCallback onConfirm,
    String confirmText = "确定",
    bool hideCancel = false,
  }) {
    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                content,
              ],
            ),
          ),
          
          // 按钮分割横线
          const Divider(height: 1, color: Color(0xFFF1F3F4)),
          
          IntrinsicHeight(
            child: Row(
              children: [
                if (!hideCancel)
                  Expanded(
                    child: InkWell(
                      // 复刻按压反馈形状
                      onTap: () => Navigator.pop(context),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        alignment: Alignment.center,
                        child: const Text("取消", style: TextStyle(color: Color(0xFF5F6368), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                
                // 复刻图中中间那条细细的竖线
                if (!hideCancel)
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F3F4), indent: 12, endIndent: 12),
                
                Expanded(
                  child: InkWell(
                    onTap: onConfirm,
                    borderRadius: hideCancel 
                        ? const BorderRadius.vertical(bottom: Radius.circular(32)) 
                        : const BorderRadius.only(bottomRight: Radius.circular(32)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      alignment: Alignment.center,
                      child: Text(confirmText, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

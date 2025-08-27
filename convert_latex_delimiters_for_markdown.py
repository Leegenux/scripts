import pyperclip

def translate_latex(text: str) -> str:
    """
    执行 LaTeX 转义符替换：
    \\( → $ 
    \\) → $ 
    \\[ → $$ 
    \\] → $$
    """
    # 如果没有反斜杠直接返回原文本
    if "\\" not in text:
        return text
    
    # 按顺序执行替换操作
    return (text
            .replace("\\(", "$")
            .replace("\\)", "$")
            .replace("\\[", "$$")
            .replace("\\]", "$$"))

# 主程序
if __name__ == "__main__":
    try:
        # 获取剪贴板内容
        original_text = pyperclip.paste()
        
        # 处理文本
        processed_text = translate_latex(original_text)
        
        # 将结果放回剪贴板
        pyperclip.copy(processed_text)
        print("转换完成！结果已复制到剪贴板。")
    except Exception as e:
        print(f"处理出错: {e}")
        print("请确保已安装 pyperclip 库 (pip install pyperclip)")
# 改进的 LaTeX 格式转换 PowerShell 脚本
# 解决了之前版本中行内和块级公式转换的错误

try {
    # 1. 获取剪贴板内容
    $clipboardText = Get-Clipboard -Raw

    if ([string]::IsNullOrEmpty($clipboardText)) {
        Write-Host "剪贴板为空，脚本已终止。"
        # 可选：暂停窗口以便用户看到消息
        # Read-Host "按 Enter 键退出"
        exit
    }

    # 2. **优先处理块级公式**
    # 将 \[ 替换为 $$，将 \] 替换为 $$
    # 这一步简单直接，不会产生歧义
    $processedText = $clipboardText -replace '\\\[', '$$$$' -replace '\\\]', '$$$$'

    # 3. **处理行内公式**
    # 使用一个正则表达式匹配整个 `\( ... \)` 结构
    #   \\\(   -> 匹配开头的 \(
    #   \s*    -> 匹配公式内容前可能存在的任意空格
    #   (.*?)  -> 非贪婪模式捕获括号内的所有内容（这是我们需要的核心内容）
    #   \s*    -> 匹配公式内容后可能存在的任意空格
    #   \\\)   -> 匹配结尾的 \)
    #
    # 替换为 '$($1)$'
    #   '$...$' -> 外层的单引号表示这是一个字面字符串
    #   $($1)  -> 这是 PowerShell 的子表达式操作符，它会计算括号内的内容
    #             $1 代表正则表达式捕获的第一个分组（也就是我们的公式内容）
    #             这样可以确保最终格式是 `$内容$`
    $processedText = $processedText -replace '\\\(\s*(.*?)\s*\\\)', '$($1)$'

    # 4. 将结果放回剪贴板
    $processedText | Set-Clipboard

    Write-Host "转换完成！结果已成功复制到剪贴板。"
    Write-Host "原始文本长度: $($clipboardText.Length), 处理后长度: $($processedText.Length)"

} catch {
    Write-Error "处理过程中发生错误: $_"
}

# 可选：如果希望脚本执行后窗口不立即关闭，取消下面一行的注释
# Read-Host "按 Enter 键退出"
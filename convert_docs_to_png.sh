#!/bin/bash

# 检查是否安装了 ImageMagick
if ! command -v convert &> /dev/null; then
    echo "错误：未安装 ImageMagick。请先安装 ImageMagick。"
    exit 1
fi

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法: $0 <文档路径或目录路径>"
    echo "支持的格式: PDF, DOCX, ODT"
    exit 1
fi

# 获取路径
path="$1"

# 检查路径是否存在
if [ ! -e "$path" ]; then
    echo "错误：路径 '$path' 不存在"
    exit 1
fi

# 如果是文件，直接转换
if [ -f "$path" ]; then
    file_ext="${path##*.}"
    file_name="${path%.*}"
    
    echo "正在处理文件: $path"
    
    # 根据文件扩展名进行转换
    case "${file_ext,,}" in
        "pdf"|"docx"|"odt")
            convert -verbose -quality 100 -fill "rgba(255,255,255,1.00)" -density 300 -alpha off "$path" "${file_name}.png"
            if [ $? -eq 0 ]; then
                echo "✓ 转换成功：${file_name}.png"
            else
                echo "✗ 转换失败：$path"
            fi
            exit 0
            ;;
        *)
            echo "错误：不支持的文件格式 '$file_ext'"
            echo "支持的格式: PDF, DOCX, ODT"
            exit 1
            ;;
    esac
fi

# 如果是目录，批量处理
if [ -d "$path" ]; then
    # 创建临时文件用于存储计数
    temp_count=$(mktemp)

    # 初始化计数器
    echo "0" > "$temp_count"
    echo "0" >> "$temp_count"
    echo "0" >> "$temp_count"

    # 处理目录下的所有文件
    echo "开始处理目录: $path"
    echo "----------------------------------------"

    # 遍历目录下的所有文件
    while IFS= read -r file_path; do
        # 更新总文件数
        total=$(sed -n '1p' "$temp_count")
        success=$(sed -n '2p' "$temp_count")
        failed=$(sed -n '3p' "$temp_count")
        
        # 更新总计数
        echo $((total + 1)) > "$temp_count"
        echo "$success" >> "$temp_count"
        echo "$failed" >> "$temp_count"
        
        file_ext="${file_path##*.}"
        file_name="${file_path%.*}"
        
        echo "正在处理: $file_path"
        
        # 根据文件扩展名进行转换
        case "${file_ext,,}" in
            "pdf")
                convert -verbose -quality 100 -fill "rgba(255,255,255,1.00)" -density 300 -alpha off "$file_path" "${file_name}.png"
                ;;
            "docx")
                convert -verbose -quality 100 -fill "rgba(255,255,255,1.00)" -density 300 -alpha off "$file_path" "${file_name}.png"
                ;;
            "odt")
                convert -verbose -quality 100 -fill "rgba(255,255,255,1.00)" -density 300 -alpha off "$file_path" "${file_name}.png"
                ;;
        esac
        
        # 检查转换是否成功
        if [ $? -eq 0 ]; then
            echo "✓ 转换成功：${file_name}.png"
            # 更新成功计数
            total=$(sed -n '1p' "$temp_count")
            success=$(sed -n '2p' "$temp_count")
            failed=$(sed -n '3p' "$temp_count")
            echo "$total" > "$temp_count"
            echo $((success + 1)) >> "$temp_count"
            echo "$failed" >> "$temp_count"
        else
            echo "✗ 转换失败：$file_path"
            # 更新失败计数
            total=$(sed -n '1p' "$temp_count")
            success=$(sed -n '2p' "$temp_count")
            failed=$(sed -n '3p' "$temp_count")
            echo "$total" > "$temp_count"
            echo "$success" >> "$temp_count"
            echo $((failed + 1)) >> "$temp_count"
        fi
        echo "----------------------------------------"
    done < <(find "$path" -type f \( -name "*.pdf" -o -name "*.docx" -o -name "*.odt" \))

    # 读取最终计数
    total_files=$(sed -n '1p' "$temp_count")
    converted_files=$(sed -n '2p' "$temp_count")
    failed_files=$(sed -n '3p' "$temp_count")

    # 删除临时文件
    rm "$temp_count"

    # 显示统计信息
    echo "转换完成！"
    echo "总文件数: $total_files"
    echo "成功转换: $converted_files"
    echo "转换失败: $failed_files"
fi 
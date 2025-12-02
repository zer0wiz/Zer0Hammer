-- 기본 템플릿 (dark theme, monospace font)
local template = {
    name = "default",
    description = "기본 다크 테마 템플릿",
    
    html = [[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            margin: 0;
            padding: 20px;
            background-color: %s;
            color: %s;
            font-family: %s;
            font-size: %dpx;
            line-height: 1.6;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            box-sizing: border-box;
        }
        .card {
            background-color: %s;
            border-radius: 12px;
            box-shadow: 0 8px 32px %s;
            border: 1px solid %s;
            overflow: hidden;
            width: 100%%;
            max-width: 100%%;
            height: calc(100vh - 40px);
            display: flex;
            flex-direction: column;
        }
        .header {
            background: linear-gradient(135deg, %s, #45a049);
            color: white;
            padding: 20px;
            font-weight: 600;
            font-size: 18px;
            border-bottom: 1px solid %s;
        }
        .content-container {
            flex: 1;
            overflow-y: auto;
            padding: 20px;
        }
        .content {
            white-space: pre-wrap;
            word-wrap: break-word;
            font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
            font-size: 13px;
            line-height: 1.5;
        }
        .scrollbar {
            scrollbar-width: thin;
            scrollbar-color: #666 %s;
        }
        .scrollbar::-webkit-scrollbar {
            width: 8px;
        }
        .scrollbar::-webkit-scrollbar-track {
            background: %s;
        }
        .scrollbar::-webkit-scrollbar-thumb {
            background: #666;
            border-radius: 4px;
        }
        .scrollbar::-webkit-scrollbar-thumb:hover {
            background: #888;
        }
        .loading {
            text-align: center;
            color: #888;
            font-style: italic;
        }
        .error {
            color: #ff6b6b;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">%s</div>
        <div class="content-container scrollbar">
            <div class="content">%s</div>
        </div>
    </div>
</body>
</html>
]],
    
    -- 기본 스타일 설정
    styles = {
        backgroundColor = "#2d2d2d",
        textColor = "#ffffff",
        fontFamily = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        fontSize = 14,
        borderColor = "#4CAF50",
        cardBackground = "#3d3d3d",
        shadowColor = "rgba(0, 0, 0, 0.3)"
    }
}

return template

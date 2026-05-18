<x-layouts.admin>
    <div class="min-h-screen bg-gray-900 p-6">
        <!-- Header -->
        <div class="mb-6 flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold text-white">SDUI Builder Pro</h1>
                <p class="text-gray-400 mt-1">محرر احترافي مع معاينة دقيقة 100%</p>
            </div>
            <div class="flex gap-3">
                <button onclick="saveLayout()" class="px-6 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg font-bold shadow-lg transition">
                    💾 حفظ التغييرات
                </button>
                <button onclick="location.reload()" class="px-6 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg transition">
                    🔄 إعادة تحميل
                </button>
            </div>
        </div>

        @if(session('success'))
            <div class="mb-6 bg-green-500/20 border-2 border-green-500 text-green-200 px-6 py-4 rounded-lg font-bold">
                ✅ {{ session('success') }}
            </div>
        @endif

        <!-- Main Layout: 3 Columns -->
        <div class="grid grid-cols-12 gap-6">
            <!-- Column 1: Widget Tree (3/12) -->
            <div class="col-span-3 bg-gray-800 rounded-2xl p-6 shadow-2xl max-h-[calc(100vh-200px)] overflow-y-auto">
                <h2 class="text-xl font-bold text-white mb-4 flex items-center gap-2">
                    <span>🌳</span>
                    <span>شجرة الودجات</span>
                </h2>
                
                <div id="widgetTree" class="space-y-2">
                    <!-- Populated by JS -->
                </div>
            </div>

            <!-- Column 2: Properties Panel (4/12) -->
            <div class="col-span-4 bg-gray-800 rounded-2xl p-6 shadow-2xl max-h-[calc(100vh-200px)] overflow-y-auto">
                <h2 class="text-xl font-bold text-white mb-4 flex items-center gap-2">
                    <span>⚙️</span>
                    <span>الخصائص</span>
                </h2>
                
                <div id="propertiesPanel" class="space-y-4">
                    <div class="text-center py-12 text-gray-400">
                        <p class="text-4xl mb-3">👆</p>
                        <p>اختر widget من الشجرة لتعديل خصائصه</p>
                    </div>
                </div>
            </div>

            <!-- Column 3: Live Preview (5/12) -->
            <div class="col-span-5 bg-gray-800 rounded-2xl p-6 shadow-2xl sticky top-6">
                <h2 class="text-xl font-bold text-white mb-4 flex items-center gap-2">
                    <span>📱</span>
                    <span>معاينة مباشرة</span>
                    <span class="text-xs bg-green-600 px-2 py-1 rounded">100% دقيقة</span>
                </h2>
                
                <!-- Phone Frame -->
                <div class="mx-auto relative" style="width: 375px;">
                    <!-- Phone Border with notch -->
                    <div class="relative bg-black rounded-[50px] border-[14px] border-gray-900 shadow-2xl">
                        <!-- Notch -->
                        <div class="absolute top-0 left-1/2 transform -translate-x-1/2 w-40 h-7 bg-black rounded-b-3xl z-10"></div>
                        
                        <!-- Status Bar -->
                        <div class="h-11 bg-black flex items-center justify-between px-8 text-white text-xs relative z-0">
                            <span class="font-semibold">9:41</span>
                            <div class="flex gap-1 items-center">
                                <svg class="w-4 h-3" fill="currentColor" viewBox="0 0 16 16"><path d="M2 2a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2H2zm0 1h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/></svg>
                                <svg class="w-4 h-3" fill="currentColor" viewBox="0 0 16 16"><path d="M11.5 1a.5.5 0 0 1 .5.5v11a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5v-11a.5.5 0 0 1 .5-.5h7z"/></svg>
                            </div>
                        </div>
                        
                        <!-- Content Area (scrollable) with BACKGROUND IMAGE -->
                        <div id="preview" class="h-[667px] overflow-y-auto relative" style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
                            <!-- Background Image Layer (will be set by JS) -->
                            <div id="previewBackground" class="absolute inset-0 z-0">
                                <!-- Background will be set by JavaScript -->
                            </div>
                            
                            <!-- Content Layer -->
                            <div id="previewContent" class="relative z-10 p-5">
                                <!-- Preview widgets will be rendered here -->
                            </div>
                        </div>
                        
                        <!-- Home Indicator -->
                        <div class="h-8 bg-black flex items-center justify-center">
                            <div class="w-32 h-1 bg-white/30 rounded-full"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // ==================== DATA ====================
        let widgets = @json($widgets);
        let layoutData = { type: 'column', children: widgets };
        let selectedWidgetPath = null;
        let currentBackgroundImage = @json($backgroundImage ?? '/assets/images/background.png');

        console.log('🚀 SDUI Builder Pro loaded');
        console.log('📊 Widgets:', widgets.length);
        console.log('🖼️ Background:', currentBackgroundImage);

        // ==================== INITIALIZATION ====================
        document.addEventListener('DOMContentLoaded', function() {
            renderWidgetTree();
            renderPreview();
        });

        // ==================== WIDGET TREE ====================
        function renderWidgetTree() {
            const container = document.getElementById('widgetTree');
            container.innerHTML = '';
            
            if (Array.isArray(layoutData.children) && layoutData.children.length > 0) {
                layoutData.children.forEach((widget, index) => {
                    container.appendChild(createTreeNode(widget, ['children', index], 0));
                });
            }
        }

        function createTreeNode(widget, path, depth) {
            const div = document.createElement('div');
            div.className = 'mb-1';
            
            const button = document.createElement('button');
            button.className = `w-full text-left px-3 py-2 rounded-lg transition flex items-center gap-2 ${
                JSON.stringify(selectedWidgetPath) === JSON.stringify(path) 
                    ? 'bg-blue-600 text-white' 
                    : 'bg-gray-700 hover:bg-gray-600 text-gray-200'
            }`;
            button.style.paddingLeft = `${depth * 12 + 12}px`;
            
            button.innerHTML = `
                <span class="text-lg">${getWidgetIcon(widget.type)}</span>
                <span class="flex-1 text-sm font-medium truncate">${getWidgetLabel(widget)}</span>
                ${widget.children && widget.children.length > 0 ? `<span class="text-xs bg-gray-600 px-2 py-0.5 rounded">${widget.children.length}</span>` : ''}
            `;
            
            button.onclick = () => selectWidget(path);
            div.appendChild(button);
            
            // Render children
            if (widget.children && widget.children.length > 0) {
                const childrenContainer = document.createElement('div');
                childrenContainer.className = 'mt-1';
                widget.children.forEach((child, index) => {
                    childrenContainer.appendChild(createTreeNode(child, [...path, 'children', index], depth + 1));
                });
                div.appendChild(childrenContainer);
            }
            
            return div;
        }

        function getWidgetIcon(type) {
            const icons = {
                'spacer': '📏',
                'padding': '📐',
                'container': '📦',
                'text': '📝',
                'row': '↔️',
                'column': '↕️',
                'icon': '⭐',
                'flexible': '🔲',
                'driversList': '👥',
            };
            return icons[type] || '📦';
        }

        function getWidgetLabel(widget) {
            if (widget.type === 'text') return widget.props?.value?.substring(0, 20) || 'نص';
            if (widget.type === 'icon') return `أيقونة: ${widget.props?.icon || 'star'}`;
            if (widget.type === 'spacer') return `مسافة: ${widget.props?.height || widget.props?.width || 10}px`;
            if (widget.type === 'flexible') return `Flexible (${widget.props?.flex || 1})`;
            
            const labels = {
                'padding': 'حشوة',
                'container': 'حاوية',
                'row': 'صف',
                'column': 'عمود',
                'driversList': 'قائمة السائقين',
            };
            return labels[widget.type] || widget.type;
        }

        // ==================== WIDGET SELECTION ====================
        function selectWidget(path) {
            selectedWidgetPath = path;
            renderWidgetTree();
            renderPropertiesPanel();
            renderPreview(); // Re-render preview to show highlight
        }

        function getWidgetByPath(path) {
            let widget = layoutData;
            for (let key of path) {
                widget = widget[key];
            }
            return widget;
        }

        // ==================== PROPERTIES PANEL ====================
        function renderPropertiesPanel() {
            const panel = document.getElementById('propertiesPanel');
            
            if (!selectedWidgetPath) {
                panel.innerHTML = `
                    <div class="text-center py-12 text-gray-400">
                        <p class="text-4xl mb-3">👆</p>
                        <p>اختر widget من الشجرة</p>
                    </div>
                `;
                return;
            }
            
            const widget = getWidgetByPath(selectedWidgetPath);
            panel.innerHTML = '';
            
            // Widget Type Header
            const header = document.createElement('div');
            header.className = 'bg-blue-900/30 border-2 border-blue-500 rounded-lg p-4 mb-4';
            header.innerHTML = `
                <div class="flex items-center gap-3">
                    <span class="text-3xl">${getWidgetIcon(widget.type)}</span>
                    <div>
                        <h3 class="text-white font-bold text-lg">${getWidgetLabel(widget)}</h3>
                        <p class="text-blue-300 text-sm">${widget.type}</p>
                    </div>
                </div>
            `;
            panel.appendChild(header);
            
            // Properties based on type
            if (widget.type === 'text') {
                panel.appendChild(createTextProperties(widget));
            } else if (widget.type === 'container') {
                panel.appendChild(createContainerProperties(widget));
            } else if (widget.type === 'spacer') {
                panel.appendChild(createSpacerProperties(widget));
            } else if (widget.type === 'padding') {
                panel.appendChild(createPaddingProperties(widget));
            } else if (widget.type === 'icon') {
                panel.appendChild(createIconProperties(widget));
            } else if (widget.type === 'flexible') {
                panel.appendChild(createFlexibleProperties(widget));
            } else {
                panel.appendChild(createGenericProperties(widget));
            }
        }

        function createTextProperties(widget) {
            const div = document.createElement('div');
            div.className = 'space-y-4';
            div.innerHTML = `
                <div>
                    <label class="block text-sm font-bold text-gray-300 mb-2">📝 النص:</label>
                    <textarea 
                        oninput="updateProp('props.value', this.value)" 
                        class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600 focus:border-blue-500 focus:outline-none resize-none"
                        rows="3"
                    >${widget.props?.value || ''}</textarea>
                </div>
                
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">📏 حجم الخط:</label>
                        <input type="number" 
                               value="${widget.props?.style?.fontSize || 14}" 
                               oninput="updateProp('props.style.fontSize', parseInt(this.value))"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600 focus:border-blue-500">
                    </div>
                    
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">🎨 اللون:</label>
                        <input type="color" 
                               value="${widget.props?.style?.color || '#FFFFFF'}" 
                               oninput="updateProp('props.style.color', this.value)"
                               class="w-full h-12 bg-gray-700 rounded-lg border-2 border-gray-600 cursor-pointer">
                    </div>
                </div>
                
                <div>
                    <label class="block text-sm font-bold text-gray-300 mb-2">📊 سُمك الخط:</label>
                    <select onchange="updateProp('props.style.fontWeight', this.value)"
                            class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                        <option value="normal" ${widget.props?.style?.fontWeight === 'normal' ? 'selected' : ''}>عادي</option>
                        <option value="w600" ${widget.props?.style?.fontWeight === 'w600' ? 'selected' : ''}>نصف عريض</option>
                        <option value="bold" ${widget.props?.style?.fontWeight === 'bold' ? 'selected' : ''}>عريض</option>
                    </select>
                </div>
            `;
            return div;
        }

        function createContainerProperties(widget) {
            const div = document.createElement('div');
            div.className = 'space-y-4';
            div.innerHTML = `
                <div>
                    <label class="block text-sm font-bold text-gray-300 mb-2">🎨 لون الخلفية:</label>
                    <input type="color" 
                           value="${widget.props?.color || '#1F2937'}" 
                           oninput="updateProp('props.color', this.value)"
                           class="w-full h-12 bg-gray-700 rounded-lg border-2 border-gray-600 cursor-pointer">
                </div>
                
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">📏 الارتفاع:</label>
                        <input type="number" 
                               value="${widget.props?.height || ''}" 
                               oninput="updateProp('props.height', parseInt(this.value) || null)"
                               placeholder="auto"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                    
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">🔲 الانحناء:</label>
                        <input type="number" 
                               value="${widget.props?.borderRadius || 0}" 
                               oninput="updateProp('props.borderRadius', parseInt(this.value))"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                </div>
            `;
            return div;
        }

        function createSpacerProperties(widget) {
            const div = document.createElement('div');
            div.className = 'space-y-4';
            div.innerHTML = `
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">⬆️ الارتفاع:</label>
                        <input type="number" 
                               value="${widget.props?.height || ''}" 
                               oninput="updateProp('props.height', parseInt(this.value) || null)"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                    
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">↔️ العرض:</label>
                        <input type="number" 
                               value="${widget.props?.width || ''}" 
                               oninput="updateProp('props.width', parseInt(this.value) || null)"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                </div>
            `;
            return div;
        }

        function createPaddingProperties(widget) {
            const div = document.createElement('div');
            div.className = 'space-y-4';
            div.innerHTML = `
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">⬆️ أعلى:</label>
                        <input type="number" 
                               value="${widget.props?.top || 0}" 
                               oninput="updateProp('props.top', parseInt(this.value))"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">⬇️ أسفل:</label>
                        <input type="number" 
                               value="${widget.props?.bottom || 0}" 
                               oninput="updateProp('props.bottom', parseInt(this.value))"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">➡️ يمين:</label>
                        <input type="number" 
                               value="${widget.props?.right || 0}" 
                               oninput="updateProp('props.right', parseInt(this.value))"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">⬅️ يسار:</label>
                        <input type="number" 
                               value="${widget.props?.left || 0}" 
                               oninput="updateProp('props.left', parseInt(this.value))"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                </div>
            `;
            return div;
        }

        function createIconProperties(widget) {
            const div = document.createElement('div');
            div.className = 'space-y-4';
            div.innerHTML = `
                <div>
                    <label class="block text-sm font-bold text-gray-300 mb-2">⭐ الأيقونة:</label>
                    <select onchange="updateProp('props.icon', this.value)"
                            class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                        <option value="map" ${widget.props?.icon === 'map' ? 'selected' : ''}>🗺️ map</option>
                        <option value="history" ${widget.props?.icon === 'history' ? 'selected' : ''}>📜 history</option>
                        <option value="wallet" ${widget.props?.icon === 'wallet' ? 'selected' : ''}>💰 wallet</option>
                        <option value="person" ${widget.props?.icon === 'person' ? 'selected' : ''}>👤 person</option>
                        <option value="car" ${widget.props?.icon === 'car' ? 'selected' : ''}>🚗 car</option>
                    </select>
                </div>
                
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">📏 الحجم:</label>
                        <input type="number" 
                               value="${widget.props?.size || 24}" 
                               oninput="updateProp('props.size', parseInt(this.value))"
                               class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    </div>
                    
                    <div>
                        <label class="block text-sm font-bold text-gray-300 mb-2">🎨 اللون:</label>
                        <input type="color" 
                               value="${widget.props?.color || '#FFFFFF'}" 
                               oninput="updateProp('props.color', this.value)"
                               class="w-full h-12 bg-gray-700 rounded-lg border-2 border-gray-600 cursor-pointer">
                    </div>
                </div>
            `;
            return div;
        }

        function createFlexibleProperties(widget) {
            const div = document.createElement('div');
            div.className = 'space-y-4';
            div.innerHTML = `
                <div>
                    <label class="block text-sm font-bold text-gray-300 mb-2">🔲 Flex:</label>
                    <input type="number" 
                           value="${widget.props?.flex || 1}" 
                           oninput="updateProp('props.flex', parseInt(this.value))"
                           class="w-full px-4 py-3 bg-gray-700 text-white rounded-lg border-2 border-gray-600">
                    <p class="text-xs text-gray-400 mt-1">نسبة المساحة المخصصة في Row</p>
                </div>
            `;
            return div;
        }

        function createGenericProperties(widget) {
            const div = document.createElement('div');
            div.className = 'bg-gray-700 rounded-lg p-4';
            div.innerHTML = `
                <p class="text-gray-300 text-sm">لا توجد خصائص قابلة للتعديل لهذا النوع</p>
                <pre class="text-xs text-gray-400 mt-2 overflow-auto">${JSON.stringify(widget.props, null, 2)}</pre>
            `;
            return div;
        }

        // ==================== UPDATE PROPERTY ====================
        function updateProp(propPath, value) {
            const widget = getWidgetByPath(selectedWidgetPath);
            const keys = propPath.split('.');
            
            let obj = widget;
            for (let i = 0; i < keys.length - 1; i++) {
                if (!obj[keys[i]]) obj[keys[i]] = {};
                obj = obj[keys[i]];
            }
            obj[keys[keys.length - 1]] = value;
            
            console.log('✅ Updated:', propPath, '=', value);
            renderPreview();
        }

        // ==================== PREVIEW RENDERING ====================
        function renderPreview() {
            const preview = document.getElementById('previewContent');
            if (!preview) {
                console.error('Preview content layer not found!');
                return;
            }
            
            // Set background image
            const bgContainer = document.getElementById('previewBackground');
            if (bgContainer && currentBackgroundImage) {
                bgContainer.innerHTML = `
                    <img src="${currentBackgroundImage}" 
                         alt="background" 
                         class="w-full h-full object-cover"
                         style="filter: brightness(0.7);"
                         onerror="this.style.display='none';">
                `;
            }
            
            preview.innerHTML = '';
            
            if (layoutData.children) {
                layoutData.children.forEach((widget, index) => {
                    const el = renderWidget(widget, [index]);
                    if (el) preview.appendChild(el);
                });
            }
        }

        function renderWidget(widget, path = []) {
            if (!widget || !widget.type) return null;
            
            const el = document.createElement('div');
            
            // Add data-path for selection tracking
            const widgetPath = path.join('.');
            el.setAttribute('data-widget-path', widgetPath);
            
            // Add click handler for selection
            el.addEventListener('click', (e) => {
                e.stopPropagation();
                console.log('Widget clicked:', widgetPath); // Debug
                selectWidget(path);
            });
            
            // NEW APPROACH: Use BORDER instead of outline
            const currentPath = selectedWidgetPath ? selectedWidgetPath.join('.') : null;
            if (widgetPath === currentPath) {
                el.style.border = '5px solid #EF4444'; // RED border - very visible!
                el.style.backgroundColor = 'rgba(239, 68, 68, 0.1)'; // Red tint
                el.style.position = 'relative';
                el.style.zIndex = '9999';
                el.style.padding = '8px';
                el.style.margin = '4px';
                el.style.borderRadius = '8px';
                console.log('Highlighting widget:', widgetPath); // Debug
            }
            
            // SPACER
            if (widget.type === 'spacer') {
                if (widget.props?.height) el.style.height = `${widget.props.height}px`;
                if (widget.props?.width) el.style.width = `${widget.props.width}px`;
                el.style.flexShrink = '0';
                // Make spacer visible when selected
                if (widgetPath === currentPath) {
                    el.style.backgroundColor = 'rgba(59, 130, 246, 0.1)';
                }
            }
            
            // PADDING
            else if (widget.type === 'padding') {
                el.style.paddingTop = `${widget.props?.top || 0}px`;
                el.style.paddingBottom = `${widget.props?.bottom || 0}px`;
                el.style.paddingLeft = `${widget.props?.left || 0}px`;
                el.style.paddingRight = `${widget.props?.right || 0}px`;
                if (widget.children) {
                    widget.children.forEach((child, index) => {
                        const childEl = renderWidget(child, [...path, 'children', index]);
                        if (childEl) el.appendChild(childEl);
                    });
                }
            }
            
            // TEXT
            else if (widget.type === 'text') {
                el.textContent = widget.props?.value || '';
                el.style.fontSize = `${widget.props?.style?.fontSize || 14}px`;
                el.style.color = widget.props?.style?.color || '#FFFFFF';
                el.style.fontWeight = widget.props?.style?.fontWeight === 'w600' ? '600' : 
                                     widget.props?.style?.fontWeight === 'bold' ? 'bold' : 'normal';
                el.style.textAlign = 'center';
                el.style.direction = 'rtl';
                el.style.lineHeight = '1.5';
            }
            
            // CONTAINER
            else if (widget.type === 'container') {
                // Background: gradient or solid color
                if (widget.props?.gradient) {
                    const colors = widget.props.gradient.colors || ['#1F2937', '#1F2937'];
                    el.style.background = `linear-gradient(135deg, ${colors[0]}, ${colors[1]})`;
                } else if (widget.props?.color) {
                    // Handle color with opacity (e.g., #1F2937CC)
                    el.style.backgroundColor = widget.props.color;
                }
                
                // Dimensions
                if (widget.props?.height) el.style.height = `${widget.props.height}px`;
                if (widget.props?.width) el.style.width = `${widget.props.width}px`;
                else el.style.width = '100%';
                
                // Border radius
                el.style.borderRadius = `${widget.props?.borderRadius || 0}px`;
                
                // Border
                if (widget.props?.border) {
                    const borderWidth = widget.props?.borderWidth || 1;
                    const borderColor = widget.props?.borderColor || '#374151';
                    el.style.border = `${borderWidth}px solid ${borderColor}`;
                }
                
                // Box shadow
                if (widget.props?.boxShadow && Array.isArray(widget.props.boxShadow)) {
                    const shadows = widget.props.boxShadow.map(shadow => {
                        const color = shadow.color || '#00000066';
                        const blur = shadow.blurRadius || 0;
                        const offsetX = shadow.offsetX || 0;
                        const offsetY = shadow.offsetY || 0;
                        return `${offsetX}px ${offsetY}px ${blur}px ${color}`;
                    });
                    el.style.boxShadow = shadows.join(', ');
                }
                
                // Padding
                if (widget.props?.padding?.all) {
                    el.style.padding = `${widget.props.padding.all}px`;
                } else if (widget.props?.padding) {
                    el.style.paddingTop = `${widget.props.padding.top || 0}px`;
                    el.style.paddingBottom = `${widget.props.padding.bottom || 0}px`;
                    el.style.paddingLeft = `${widget.props.padding.left || 0}px`;
                    el.style.paddingRight = `${widget.props.padding.right || 0}px`;
                }
                
                // Layout
                el.style.display = 'flex';
                el.style.flexDirection = 'column';
                el.style.alignItems = 'center';
                el.style.justifyContent = 'center';
                el.style.overflow = 'hidden';
                el.style.cursor = widget.props?.action ? 'pointer' : 'default';
                
                // Children
                if (widget.children) {
                    widget.children.forEach(child => {
                        const childEl = renderWidget(child);
                        if (childEl) el.appendChild(childEl);
                    });
                }
            }
            
            // ROW
            else if (widget.type === 'row') {
                el.style.display = 'flex';
                el.style.flexDirection = 'row';
                el.style.width = '100%';
                el.style.gap = '0';
                
                if (widget.children) {
                    widget.children.forEach(child => {
                        const childEl = renderWidget(child);
                        if (childEl) el.appendChild(childEl);
                    });
                }
            }
            
            // COLUMN
            else if (widget.type === 'column') {
                el.style.display = 'flex';
                el.style.flexDirection = 'column';
                el.style.width = '100%';
                el.style.alignItems = widget.props?.crossAxisAlignment === 'center' ? 'center' : 'stretch';
                el.style.justifyContent = widget.props?.mainAxisAlignment === 'center' ? 'center' : 'flex-start';
                
                if (widget.children) {
                    widget.children.forEach(child => {
                        const childEl = renderWidget(child);
                        if (childEl) el.appendChild(childEl);
                    });
                }
            }
            
            // FLEXIBLE
            else if (widget.type === 'flexible') {
                el.style.flex = widget.props?.flex || 1;
                if (widget.children && widget.children.length > 0) {
                    const childEl = renderWidget(widget.children[0]);
                    if (childEl) {
                        childEl.style.width = '100%';
                        childEl.style.height = '100%';
                        el.appendChild(childEl);
                    }
                }
            }
            
            // ICON
            else if (widget.type === 'icon') {
                const iconMap = {
                    'map': '🗺️',
                    'history': '📜',
                    'wallet': '💰',
                    'person': '👤',
                    'car': '🚗',
                };
                el.textContent = iconMap[widget.props?.icon] || '⭐';
                el.style.fontSize = `${widget.props?.size || 24}px`;
                el.style.color = widget.props?.color || '#FFFFFF';
                el.style.lineHeight = '1';
            }
            
            // DRIVERS LIST
            else if (widget.type === 'driversList') {
                el.innerHTML = `
                    <div style="padding: 16px; background: rgba(31, 41, 55, 0.5); border-radius: 12px; margin: 8px; text-align: center; color: #9CA3AF; font-size: 12px;">
                        📋 قائمة السائقين (ديناميكية)
                    </div>
                `;
            }
            
            return el;
        }

        // ==================== SAVE ====================
        async function saveLayout() {
            try {
                const response = await fetch('/admin/sdui', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    },
                    body: JSON.stringify({
                        key: 'home',
                        widgets: layoutData.children,
                    }),
                });

                const data = await response.json();
                
                if (data.success) {
                    alert('✅ تم حفظ التغييرات بنجاح!\n\nأعد تشغيل التطبيق لرؤية التغييرات.');
                    location.reload();
                } else {
                    alert('❌ حدث خطأ أثناء الحفظ');
                }
            } catch (error) {
                console.error('Error:', error);
                alert('❌ حدث خطأ أثناء الحفظ');
            }
        }
    </script>

    <style>
        /* Scrollbar styling */
        #widgetTree::-webkit-scrollbar,
        #propertiesPanel::-webkit-scrollbar,
        #preview::-webkit-scrollbar {
            width: 8px;
        }
        #widgetTree::-webkit-scrollbar-track,
        #propertiesPanel::-webkit-scrollbar-track,
        #preview::-webkit-scrollbar-track {
            background: #1f2937;
        }
        #widgetTree::-webkit-scrollbar-thumb,
        #propertiesPanel::-webkit-scrollbar-thumb,
        #preview::-webkit-scrollbar-thumb {
            background: #4b5563;
            border-radius: 4px;
        }
        
        /* Color picker */
        input[type="color"] {
            -webkit-appearance: none;
            border: none;
            cursor: pointer;
        }
        input[type="color"]::-webkit-color-swatch-wrapper {
            padding: 0;
        }
        input[type="color"]::-webkit-color-swatch {
            border: none;
            border-radius: 6px;
        }
    </style>
</x-layouts.admin>

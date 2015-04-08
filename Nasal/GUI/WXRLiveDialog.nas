var wxr_tree = "/instrumentation/wxr";
var WUndergroundUrl = 'http://www.wunderground.com/weather/api';
var saved_conf = getprop("/sim/fg-home") ~ "/Export/wxr_api.xml";

var WXRLiveDialog = {
    new: func(){
        var m = {
            parents: [WXRLiveDialog]
        };
        m._update();
        return m;
    },
    _update: func(){
        me.liveWXR = getprop('instrumentation/efis/mfd/wxr-live-enabled');
        me._loadConf();
        if(me.liveWXR == nil) me.liveWXR = 0;
    },
    _loadConf: func(){ 
        if(io.stat(saved_conf) != nil)
            io.read_properties(saved_conf, wxr_tree);
        me.apiKey = getprop(wxr_tree~"/api-key");
        if(!me.apiKey or me.apiKey == '' or me.apiKey == 'YOUR API KEY'){
            me.apiKey = nil;
            me.liveWXR = 0;
            setprop('instrumentation/efis/mfd/wxr-live-enabled', 0);
        }
    },
    _createLabel: func(text){
        var lbl = canvas.gui.widgets.Label.new(
            me._root, 
            canvas.style,
            {wordWrap: 1}
        );
        lbl.setText(text);
        return lbl;
    },
    _getAPIURL: func(){
        var lat = 51.506423;
        var lon = -0.037054;
        return "http://api.wunderground.com/api/"~me.apiKey~
            "/radar/image.png?centerlat="~lat~"&centerlon="~lon~
            "&radius=20&width=100&height=100&smooth=1";
    },
    show: func(){
        var bgColor = canvas.style.getColor("bg_color");
        var self = me;
        me._dialog = canvas.Window.new([400,300], 'dialog');
        #me._dialog.set("resize", 1);
        me._root = me._dialog.getCanvas(1)
                             .set("background", bgColor)
                             .createGroup();
        var vbox = canvas.VBoxLayout.new();
        me._dialog.setLayout(vbox);
        vbox.setContentsMargin(12);
        var r = me._root;
        var s = canvas.style;
        me.checkbox = canvas.gui.widgets.CheckBox.new(r,s,{});
        me.checkbox.listen('toggled', func(e){
            me.liveWXR = e.detail.checked;
            self.updateState();
        });
        var hbox = canvas.HBoxLayout.new();
        vbox.addItem(hbox);
        hbox.addItem(me.checkbox);
        hbox.addItem(me._createLabel('Use Live WXR on ND'));
        me.configContainer = canvas.VBoxLayout.new();
        var msg = "In order to use the Live WXR you need to obtain a free "~
                  "API Key from Wunderground ("~WUndergroundUrl~")." ;
        vbox.addItem(me.configContainer);
        me.configContainer.addItem(me._createLabel(msg));
        me.openSiteButton = canvas.gui.widgets.Button.new(r,s,{});
        me.openSiteButton.setText('Get a free API Key');
        me.openSiteButton.listen('clicked', func(){
            fgcommand('open-browser', props.Node.new({
                url: WUndergroundUrl
            }));
        });
        me.configContainer.addItem(me.openSiteButton);
        me.configContainer.addItem(me._createLabel('API Key:'));
        hbox = canvas.HBoxLayout.new();
        me.keyField = canvas.gui.widgets.LineEdit.new(r,s,{});
        me.pasteButton = canvas.gui.widgets.Button.new(r,s,{});
        me.pasteButton.setText('Paste From Clipboard');
        me.pasteButton.listen('clicked', func(){
            self.keyField.setText(clipboard.getText());
        });
        hbox.addItem(me.keyField);
        hbox.addItem(me.pasteButton);
        me.configContainer.addItem(hbox);
        hbox = canvas.HBoxLayout.new();
        vbox.addItem(hbox);
        me.saveButton = canvas.gui.widgets.Button.new(r,s,{});
        me.saveButton.setText('Save');
        me.saveButton.listen('clicked', func(){
            self.saveButton.setEnabled(0);
            self.check(func(ok){
                if(ok){
                    self.save();
                    #self.saveButton.setEnabled(1);
                    self._dialog.del();
                } else {
                    self.saveButton.setEnabled(1);
                }
            });
        });
        hbox.addItem(me.saveButton);
        me.update();
    },
    updateState: func(){
        var wdgts = [
            me.openSiteButton,
            me.keyField,
            me.pasteButton
        ];
        foreach(var w; wdgts){
            w.setEnabled(me.liveWXR);
        }
    },
    update: func(){
        var liveEnabled = me.liveWXR;
        me.checkbox.setChecked(liveEnabled);
        if(me.apiKey != nil)
            me.keyField.setText(me.apiKey);
        else 
            me.keyField.setText('');
    },
    check: func(cb){
        me.apiKey = me.keyField.text();
        if(me.liveWXR){
            var key = me.apiKey;
            if(key == nil or key == ''){
                me.liveWXR = 0;
                me.updateState();
                var msg = "API Key is required!";
                canvas.MessageBox.warning('Warning', msg);
                cb(0);
                return 0;
            } else {
                var url = me._getAPIURL();
                gui.popupTip('Checking API Key...');
                http.load(url)
                    .fail(func(){
                        var msg = "Could not access to Weather API, "~
                                  "please check your internet connection.";
                        canvas.MessageBox.critical('Warning', msg);
                        cb(0);
                        return;
                    })
                    .done(func(r){
                        var body = r.response;
                        var errfound = ((find('keynotfound', body) >= 0) and 
                                        (find('error', body) >= 0));
                        if(errfound){
                            var msg = "Your API Key is not valid!";
                            canvas.MessageBox.critical('Warning', msg);
                            cb(0);
                            return;
                        }
                        cb(1);
                    });
            }
        } else {
            cb(1);
        }
    },
    save: func(){
        setprop('instrumentation/efis/mfd/wxr-live-enabled', me.liveWXR);
        setprop(wxr_tree~"/api-key", me.apiKey);
        io.write_properties(saved_conf, wxr_tree);
    }
};

(function() {

    this.CandlestickTVUI = flight.component(function() {
        this.init = function(event, data) {/*nothing*/};

        return this.after('initialize', function() {
            var udf_url = $(location).attr('protocol') +
                '//' +
                $(location).attr('host') +
                '/api/v2';
            var widget = window.tvWidget = new TradingView.widget({
                symbol: gon.market.id,
                datafeed: new window.Datafeeds.UDFCompatibleDatafeed( udf_url, 60000 ),
                interval: '1D',
                container_id: 'candlestick_tv',
                library_path: '/assets/charting_library/',
                locale: gon.local.substring(0, 2),

                fullscreen: false,
                autosize: true,
                toolbar_bg: "#29363e",
                padding: 0,
                allow_symbol_change: false,
                details: false,
                hotlist: false,
                show_popup_button: false,

                studies_overrides: {},
                loading_screen: { backgroundColor: "#29363e" },
                hide_top_toolbar: false,
                //toolbar_bg: '#007b02',
                hideideas: false,
                debug: false,
                drawings_access: { type: 'black', tools: [ { name: "Regression Trend" } ] },

                enabled_features: ["remove_library_container_border"],

                disabled_features: [
                    "header_symbol_search"
                ],
                overrides: {
                    "paneProperties.background": "#29363e",
                    "paneProperties.vertGridProperties.color": "#454545",
                    "paneProperties.horzGridProperties.color": "#454545",
                    "symbolWatermarkProperties.transparency": 90,
                    "scalesProperties.textColor" : "#AAA",
                    "volumePaneSize": "small",

                    //	Series style. See the supported values below
                    //		bars = 0
                    //		candles = 1
                    //		line = 2
                    //		area = 3
                    //		heiken ashi = 8
                    //		hollow candles = 9
                    "mainSeriesProperties.style": 8,
                    "scalesProperties.backgroundColor": "#ffffff",
                    "scalesProperties.lineColor": "#a1b5c1",
                    "scalesProperties.textColor": "#a1b5c1"

                    //SET BAR candleStyle DOWN
                    //"mainSeriesProperties.candleStyle.downColor": "cyan",
                    //"mainSeriesProperties.candleStyle.borderDownColor": "cyan",

                    //SET BAR candleStyle UP
                    //"mainSeriesProperties.candleStyle.upColor": "black",
                    //"mainSeriesProperties.candleStyle.borderUpColor": "black",

                }
            });
            widget.onChartReady(function() { /*nothing*/ });

        });
    });
}).call(this);

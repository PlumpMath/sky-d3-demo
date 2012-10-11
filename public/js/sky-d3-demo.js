(function() {
    //--------------------------------------------------------------------------
    // Initialization
    //--------------------------------------------------------------------------

    var margin = {top: 1, right: 1, bottom: 6, left: 1},
        width = 960 - margin.left - margin.right,
        height = 500 - margin.top - margin.bottom;

    var formatNumber = d3.format(",.0f"),
        format = function(d) { return formatNumber(d) + " times"; },
        color = d3.scale.category20();

    var svg = d3.select("#chart").append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
      .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    var sankey = d3.sankey()
        .nodeWidth(15)
        .nodePadding(10)
        .size([width, height]);

    var path = sankey.link();

    // Converts the event name into something a little prettier.
    for(var i=0; i<actions.length; i++) {
        var action = actions[i];
        action.name = action.name.replace("Event", "").replace(/([^A-Z])([A-Z])/g, "$1 $2");
    }
    
    // Populate initial action list.
    $.each(actions, function(index, action) {
        $('#initialAction').append($('<option>', {value:action.id, text:action.name}));
    });


    //--------------------------------------------------------------------------
    // Chart Functions
    //--------------------------------------------------------------------------

    function loadChart(rootActionIds) {
        if(rootActionIds.length > 3) {
            alert("This demo only allows 3 levels of drill-down.");
            return;
        }
        
        //updateBreadcrumb(rootActionIds, true);
        
        d3.json("/next_actions?actionIds=" + rootActionIds.join(","),
            function draw(data) {
                //updateBreadcrumb(rootActionIds, false);
                $("#chart svg g").empty();
                
                // Calculate total count.
                var totalCount = 0;
                for(var i=0; i<data.length; i++) {
                    totalCount += data[i].count;
                }
                
                // Generate root nodes and links.
                var links = [];
                var roots = [];
                for(var i=0; i<rootActionIds.length; i++) {
                    roots.push({level:0, isRoot:true, targetActionIds:rootActionIds.slice(0, i+1), actionId:rootActionIds[i], name:getAction(rootActionIds[i]).name});
                    if(i > 0) {
                        links.push({source:i-1, target:i, value:totalCount});
                    }
                }
                var nodes = roots.slice();
                
                // Generate leaf nodes and links.
                for(var i=0; i<data.length; i++) {
                    var n = {level:roots.length, targetActionIds:rootActionIds.concat(data[i].actionId), actionId:data[i].actionId, name:getAction(data[i].actionId).name};
                    var l = {source:(roots.length-1), target:nodes.length, value:data[i].count};
                    nodes.push(n);
                    links.push(l);
                }
        
                sankey.nodes(nodes)
                    .links(links)
                    .layout(32);

                var link = svg.append("g").selectAll(".link")
                    .data(links)
                    .enter().append("path")
                    .attr("class", "link")
                    .attr("d", path)
                    .style("stroke-width", function(d) { return Math.max(1, d.dy); })
                    .sort(function(a, b) { return b.dy - a.dy; });

                link.append("title")
                    .text(function(d) { return d.source.name + " → " + d.target.name + "\n" + format(d.value); });

                var node = svg.append("g").selectAll(".node")
                    .data(nodes)
                    .enter().append("g")
                    .attr("class", "node")
                    .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })
                    .on("click", function(d, i) {
                        loadChart(d.targetActionIds);
                    });

                node.append("rect")
                    .attr("height", function(d) { return d.dy; })
                    .attr("width", sankey.nodeWidth())
                    .style("fill", function(d) { return d.color = color(d.name.replace(/ .*/, "")); })
                    .style("stroke", function(d) { return d3.rgb(d.color).darker(2); })
                    .append("title")
                    .text(function(d) { return d.name + "\n" + format(d.value); });

                node.append("text")
                    .attr("x", -6)
                    .attr("y", function(d) { return d.dy / 2; })
                    .attr("dy", ".35em")
                    .attr("text-anchor", "end")
                    .attr("transform", null)
                    .text(function(d) { return d.name; })
                    .filter(function(d) { return d.x < width / 2; })
                    .attr("x", 6 + sankey.nodeWidth())
                    .attr("text-anchor", "start");

                function dragmove(d) {
                    d3.select(this).attr("transform", "translate(" + d.x + "," + (d.y = Math.max(0, Math.min(height - d.dy, d3.event.y))) + ")");
                    sankey.relayout();
                    link.attr("d", path);
                }
            }
        );
    }
    
    loadChart([$("#initialAction").val()]);


    //--------------------------------------------------------------------------
    // Breadcrumb
    //--------------------------------------------------------------------------
    
    function updateBreadcrumb(actionIds, loading)
    {
        if(actionIds.length == 0) return;
        
        var html = "";
        for(var i=0; i<actionIds.length; i++) {
            var action = getAction(actionIds[i]);
            
            if(i < actionIds.length - 1) {
                html += "<li><a data-action-ids=\"[" + actionIds.slice(0, i+1).join(",") + "]\" href=\"#\">" + action.name + "</a> <span class=\"divider\">&gt;</span></li>";
            }
            else {
                html += "<li class=\"active\">" + action.name + "</li>";
            }
        }

        if(loading) {
            html += "<li class=\"active pull-right\">...</li>";
        }
        
        $(".breadcrumb").html(html);
    }

    $(".breadcrumb").on("click", "li a", function(event) {
        loadChart($(this).data("actionIds"));
        return false;
    });
    

    //--------------------------------------------------------------------------
    // Action Functions
    //--------------------------------------------------------------------------
    
    // Retrieves an action by id.
    function getAction(id) {
        for(var i=0; i<actions.length; i++) {
            if(actions[i].id == parseInt(id)) {
                return actions[i];
            }
        }
        return null;
    }
    

    //--------------------------------------------------------------------------
    // Initial Action List
    //--------------------------------------------------------------------------

    // Reset the display when a new initial event is selected.
    $("#initialAction").on("change", function(event) {
        loadChart([$("#initialAction").val()]);
    });
})();

$('.dropdown-toggle').dropdown();
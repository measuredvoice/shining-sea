$(function(){
  $.getJSON($('#scatterplot').attr('data-source'), function(rawData) {
    var data = rawData.tweets;
    console.log('here');

    // Start with the first tweet in the tweet details area.
    doPopulateTweet(data[0]);

    var margin = {top: 30, right: 10, bottom: 50, left: 60},
      width = 570 - margin.left - margin.right,
      height = 400 - margin.top - margin.bottom;
    
    var raw_score_for = function(d) {return d.kudos * 1.5 + d.engagement;}
    
    var xMax = d3.max(data, function(d) { return +d.audience; }),
      xMin = 0,
      yMax = d3.max(data, function(d) { return raw_score_for(d); }),
      yMin = 0;
    
    //Define scales
    var x = d3.scale.linear()
      .domain([xMin, xMax])
      .range([0, width]);
      
    var y = d3.scale.linear()
      .domain([yMin, yMax])
      .range([height, 0]);
      
    var colorRank = function(val){
      if (val <= 10) {
        return '#9E270D';
      } else if (val <= 50) {
        return '#045E14';
      } else if (val <= 100) {
        return '#328A42';
      } else if (val <= 250) {
        return '#82BA8D';
      } else {
        return '#CAE3CF';
      }
    };
    
    
    //Define X axis
    var xAxis = d3.svg.axis()
      .scale(x)
      .orient("bottom")
      .tickSize(-height)
      .tickFormat(d3.format("s"));
    
    //Define Y axis
    var yAxis = d3.svg.axis()
      .scale(y)
      .orient("left")
      .ticks(5)
      .tickSize(-width)
      .tickFormat(d3.format("s"));
    
    // Zoom in while keeping the origin where it is.
    var zm = d3.behavior.zoom().x(x).center([x(0),y(0)]).scaleExtent([1, 8]).on("zoom", zoom)

    var svg = d3.select("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
      .call(zm);
    
    svg.append("rect")
      .attr("width", width)
      .attr("height", height);
    
    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);
    
    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis);

    
    var poly = svg.selectAll("polygon")
      .data(data)
      .enter()
      .append("circle")
      .attr("transform", function(d, i) {
        return "translate("+x(d.audience)+","+y(raw_score_for(d))+")";
      })
      .attr("r", "5")
      .attr("title", function(d) {
        return '@' + d.screen_name;
      })
      .attr("opacity","0.8")
      .attr("data-href", function(d) {
        return d.link;
      })
      .attr("fill",function(d) {
        return colorRank(d.daily_rank);
      })
      .on("mouseover", function(d) {
        $( this ).attr("r", "10");
      })
      .on("mouseout", function(d) {
        $( this ).attr("r", "5");
      })
      .on("click", function(d) {
        $("#scatterplot circle.selected").attr("class","");
        $( this ).attr("class", "selected");
        doPopulateTweet(d)
      });

    // Add the x-axis label (audience)
    svg.append("text")
      .attr("class", "x label")
      .attr("text-anchor", "end")
      .attr("x", width)
      .attr("y", height + margin.bottom - 10)
      .text("Followers (at the time the Tweet was posted)");

    // Add the y-axis label (score)
    svg.append("text")
      .attr("class", "y label")
      .attr("text-anchor", "end")
      .attr("y", -margin.left)
      .attr("x", 0)
      .attr("dy", ".75em")
      .attr("transform", "rotate(-90)")
      .text("Retweets and favorites");

    function zoom() {
      svg.select(".x.axis").call(xAxis);
      svg.select(".y.axis").call(yAxis);
      svg.selectAll("circle")     
      .attr("transform", function(d, i) {
        return "translate("+x(d.audience)+","+y(raw_score_for(d))+")";
      })
      .attr('points','4.569,2.637 0,5.276 -4.569,2.637 -4.569,-2.637 0,-5.276 4.569,-2.637')
    }

    function doPopulateTweet(data){
      if (!data) return;

      $("#tweet-display").html('<blockquote class="twitter-tweet" data-dnt="true"><a href="' + data.link + '">Loading tweet&hellip;</a></blockquote>');
      $("#daily-rank").html(data.daily_rank);
      $("#ordinal-rank").html(data.daily_rank);
      $("#tweet-date").html(moment(data.date, 'YYYY-MM-DD').format('MMMM Do, YYYY'));
      $("#engagement-count").number(data.engagement);
      $("#kudos-count").number(data.kudos);
      $("#reach-count").number(data.reach);
      twttr.widgets.load($("#tweet-display")[0]);

      // hide the plot loader
      $("#plot-loader").hide();
    }

  });   
});

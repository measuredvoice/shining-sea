$(function(){
  $.getJSON($('#scatterplot').attr('data-source'), function(rawData) {
    var data = rawData.tweets;

    // Start with the first tweet in the tweet details area.
    $("#tweet-display").html('<blockquote class="twitter-tweet" data-dnt="true">(@someone) <a href="' + data[0].link + '">details</a></blockquote>');
    $("#daily-rank").html(data[0].daily_rank);
    $("#ordinal-rank").html(data[0].daily_rank);
    $("#tweet-date").html(moment(data[0].date, 'YYYY-MM-DD').format('MMMM Do, YYYY'));
    $("#engagement-count").number(data[0].engagement);
    $("#kudos-count").number(data[0].kudos);
    $("#reach-count").number(data[0].reach);
    twttr.widgets.load($("#tweet-display")[0]);

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
        $("#tweet-display iframe").replaceWith('<blockquote class="twitter-tweet" data-dnt="true">(@someone) <a href="' + d.link + '">details</a></blockquote>');
        $("#daily-rank").html(d.daily_rank);
        $("#ordinal-rank").html(d.daily_rank);
        $("#tweet-date").html(moment(d.date, 'YYYY-MM-DD').format('MMMM Do, YYYY'));
        $("#engagement-count").number(d.engagement);
        $("#kudos-count").number(d.kudos);
        $("#reach-count").number(d.reach);
        twttr.widgets.load($("#tweet-display")[0]);
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

	});	  
});

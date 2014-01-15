plugin = ($) ->

	"use strict"

	class Columnagram
		defaults:
			columns: 'auto'
			# balanceMethod: 'balanceCount'
			balanceMethod: 'balanceHeight'
			minWeightRepeats: 10

		constructor: (@el, config) ->
			@$el = $ @el
			@config = $.extend {}, @defaults, config
			@columnize()

		destroy: ->
			@decolumnize()

		balanceItemsIntoChunksByWeight: (items, weights, chunkCount) ->
			chunks = @balanceItemsIntoChunksByCount items, chunkCount
			calculateWeights = ->
				i = 0
				for chunk in chunks
					chunkWeight = 0
					chunkWeight += weights[j] for j in [i..i+chunk.length-1]
					i += chunk.length
					chunkWeight

			minWeight = 10000000
			minWeightRepeats = 0
			# t = 1
			while true
				# console.log t++, minWeightRepeats, minWeight
				chunkWeights = calculateWeights()
				maxWeight = Math.max chunkWeights...
				if maxWeight < minWeight
					minWeight = maxWeight
					minWeightRepeats = 0
				else if maxWeight is minWeight
					minWeightRepeats++
					return chunks if minWeightRepeats is @config.minWeightRepeats
				maxWeightChunkIndex = chunkWeights.indexOf maxWeight
				if maxWeightChunkIndex is 0 # first
					chunks[maxWeightChunkIndex+1].unshift chunks[maxWeightChunkIndex].pop()
				else if maxWeightChunkIndex is chunkWeights.length - 1 # last
					chunks[maxWeightChunkIndex-1].push chunks[maxWeightChunkIndex].shift()
				else
					chunks[maxWeightChunkIndex+1].unshift chunks[maxWeightChunkIndex].pop() if chunks[maxWeightChunkIndex].length > 1
					chunks[maxWeightChunkIndex-1].push chunks[maxWeightChunkIndex].shift() if chunks[maxWeightChunkIndex].length > 1

		balanceItemsIntoChunksByCount: (items, chunkCount) ->
			result = []
			perChunk = Math.round items.length / chunkCount
			for chunkIndex in [0..chunkCount-1]
				result.push items.slice chunkIndex * perChunk, (chunkIndex + 1) * perChunk
			result

		columnize: ($children = null) ->
			columnCount = @config.columns
			$children = @$el.children() if not $children

			chunks = switch @config.balanceMethod
				when "balanceHeight"
					heights = ($(child).outerHeight() for child in $children)
					@balanceItemsIntoChunksByWeight $children.toArray(), heights, columnCount
				when "balanceCount"
					@balanceItemsIntoChunksByCount $children, columnCount
			
			@$el.empty()

			for chunk in chunks
				$column = $("<div></div>").css
					float: "left"
					width: "#{Math.floor 100 / columnCount}%"
				$column.append chunk
				@$el.append $column

		decolumnize: (recolumnizing = no) ->
			$children = @$el.find("> div").children()
			@$el.find("> div").remove()
			if recolumnizing
				$children
			else
				@$el.append $children

		recolumnize: ->
			@columnize @decolumnize yes

	$.fn.columnagram = (method, args...) ->
		@each ->
			columnagram = $(@).data 'columnagram'
			unless columnagram
				columnagram = new Columnagram @, if typeof method is 'object' then method else {}
				$(@).data 'columnagram', columnagram

			columnagram[method].apply columnagram, args if typeof method is 'string'

# UMD
if typeof define is 'function' and define.amd # AMD
	define(['jquery'], plugin)
else # browser globals
	plugin(jQuery)

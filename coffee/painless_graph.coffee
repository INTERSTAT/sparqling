#_require cyto_style.coffee
#_require sparql_text.coffee

class window.PainlessGraph
    ###* manages the graph visualization
        TODO: palette should be in constants
        TODO: hardcoded collision distance should be in constants
    ###
    
    palette = [ "b58900", "cb4b16", "dc322f", "d33682", "6c71c4", "268bd2", "2aa198", "859900" ]
    cur_variable_value = 0
    sparql_text = null
    state_buffer = null
    state_buffer_max_length = 20


    constructor: ->
        ###*
        TODO: sparql_text should be managed by painless_sparql.coffee
        ###
        @init()
        @reshape()
        
        sparql_text = new SparqlText(@cy)
        sparql_text.update()


    reshape: =>
        ###* resets node positions in the graph view 
            TODO: it's ugly with complex graphs.
        ###
        if @cy.nodes('.node-variable').length < 3
            @cy.layout({
                name: 'circle'
            }).run()
        else
            @cy.layout({
                name:'breadthfirst'
                padding: 5
                spacingFactor: 1 
                fit:false
            }).run()


    save_state: ->
        if state_buffer == null
            state_buffer = []
        if @cy.json() != state_buffer[state_buffer.length - 1]
            state_buffer.push(@cy.json())
        if state_buffer.length >= state_buffer_max_length 
           state_buffer.shift() 


    undo : ->
        if state_buffer == null or state_buffer.length < 1
            console.warn "no saved states"
        else
            @cy.json(state_buffer[state_buffer.length - 1])
            @cy.style(generate_style())
            state_buffer.pop()
            @reshape()


    merge: (node1, node2) ->
        ###* merges node1 and node2, repositioning all node2's edges into node1 ###
        @save_state()

        for edge in node2.neighborhood('edge')
        
            # if this edge has node2 as target
            if edge.target().id() == node2.id()
                @cy.add({
                    group: 'edges'
                    data: {
                        source: edge.source().id()
                        target: node1.id()
                    }
                })

            # if this edge has node2 as source
            if edge.source().id() == node2.id()
                @cy.add({
                    group: 'edges'
                    data: {
                        source: node1.id()
                        target: edge.target().id()
                    }
                })

        # remove node2 with all its connected edges
        sparql_text.remove_from_select_boxes(node2.id())
        @cy.remove(node2) 


    add_link: (link_name, link_type) =>
        ###* adds a new link in the graph. 
            links that are not concepts (roles and attributes) add a new variable into the graph.
            links are always added to the selected variable in the graph, if there are no selected variables,   
                two new variables are created.

            links can be:
            - concepts   
            - roles
            - attributes

            TODO: use an enum to represent link types instead of hardcoded strings
        ###
        @save_state()

        if @cy.nodes(":selected").length > 0 and @cy.nodes(":selected").hasClass('node-variable')
            parent = @cy.nodes(":selected")
        else 
            par_id = "x" + cur_variable_value
            
            @cy.add({
                group: 'nodes'
                data: {
                    id: par_id
                    color: '#' + palette[cur_variable_value % palette.length];
                    label: par_id
                }
                classes: 'node-variable'
            })

            parent = @cy.getElementById(par_id)
            sparql_text.add_to_select(par_id)
            cur_variable_value += 1

        range_id = parent.id() + Math.round(Math.random()*1000)
        attr_id = link_name + Math.round(Math.random()*1000)
        dom_id = parent.id() + range_id + "d"
        var_id = "x" + cur_variable_value
        
        if link_type == "concept"
            @cy.add({
                group: 'nodes'
                data: {id: attr_id}
                classes: 'node-concept'
            })
            @cy.add({
                group: 'edges'
                data: {
                    source: parent.id()
                    target: attr_id
                }
            })

        else

            @cy.add({
                group: 'nodes'
                data: {id: range_id}
                classes: 'node-range'
            })
            @cy.add({
                group: 'edges'
                data: {
                    source: parent.id()
                    target: range_id
                }
            })
            @cy.add({
                group: 'nodes'
                data: {
                    id: attr_id
                    label: link_name
                }
                classes: 'node-attribute'
            })
            @cy.add({
                group: 'edges'
                data: {
                    source: range_id
                    target: attr_id
                }
            })
            @cy.add({
                group: 'nodes'
                data: {id: dom_id}
                classes: 'node-domain'
            })
            @cy.add({
                group: 'edges'
                data: {
                    source: attr_id
                    target: dom_id
                }}
            )

            @cy.add({
                group: 'nodes'
                data: {
                    id: var_id
                    color: '#' + palette[cur_variable_value % palette.length];
                    label: var_id
                }
                classes: 'node-variable'
            })

            sparql_text.add_to_select(var_id)
            cur_variable_value += 1
            
            @cy.add({
                group: 'edges'
                data: {
                    source: dom_id
                    target: var_id
                }
            })

        sparql_text.update()
        @reshape()
   

    compute_distance: (node1, node2) ->
        ###* computes distance between two node positions ###
        a = Math.abs(node1.position('x') - node2.position('x'))
        b = Math.abs(node1.position('y') - node2.position('y'))
        return Math.sqrt(a*a + b*b)


    check_collisions: =>
        ###* check if there are any collisions in all the node variables
        returns the colliding nodes if there are any.

        TODO: collision highlight is broken!
        TODO: remove hardcoded collision distance threshold
        ###
        for node in @cy.nodes(".node-variable")
            for node2 in @cy.nodes(".node-variable")
                if node != node2
                    if @compute_distance(node, node2) < 100
                        node.addClass('highlight')
                        node2.addClass('highlight')
                        return [node, node2]
                    else
                        node.removeClass('highlight')
 
    
    init: =>
        @cy = new cytoscape(
            container: document.getElementById("query_canvas"),
            style: generate_style()
            wheelSensitivity: 0.5
        )
        @cy.on('click', '.node-variable',
            (event) =>
                event.target.select()
                @reshape()
            )
        @cy.on('mouseup',
            ($) => 
                if @check_collisions() != undefined
                    node_tmp_arr = @check_collisions()
                    @merge(node_tmp_arr[0], node_tmp_arr[1])
            
                @reshape()
            )
        @cy.resize()

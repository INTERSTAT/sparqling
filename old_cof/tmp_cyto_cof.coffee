#_require event_management.coffee
#_require constants.coffee
#_require cyto_style.coffee

sparql_text = document.getElementById("sparql_text")
class_cur_letter = "a"
state_buffer = null
state_buffer_max_length = 20
selected_node = null

# possible types:
# node-domain
# node-range
# node-attribute
# node-role
# node-variable

elements = {
    # to be removed in final version
    nodes: [
        {data: {id: 'a'}, classes: 'node-variable'},
    ]
}

cy = new cytoscape(
    container: document.getElementById('cy'),
    elements: elements
    layout: {name: 'cose'}
    style: generate_style()
)


reshape = -> 
    console.log "reshaping"

    parents = cy.nodes('.node-variable')
    
    cy.nodes().layout({name:'circle'}).run()

    #parents.layout({
        #name: 'circle'
    #}).run()

    #for parent in parents
        
        #parent.neighborhood().layout({
                #name:'circle'
            #}).run()


add_role = (parent) ->
    range_id = parent.id() + Math.round(Math.random()*1000)
    attr_id = parent.id() + range_id + "a"
    dom_id = parent.id() + range_id + "d"
    var_id = parent.id() + range_id + "p"
    cy.add({
        group: 'nodes'
        data: {id: range_id}
        classes: 'node-range'
    })
    cy.add({
        group: 'edges'
        data: {
            source: parent.id()
            target: range_id
        }
    })
    cy.add({
        group: 'nodes'
        data: {id: attr_id}
        classes: 'node-attribute'
    })
    cy.add({
        group: 'edges'
        data: {
            source: range_id
            target: attr_id
        }
    })
    cy.add({
        group: 'nodes'
        data: {id: dom_id}
        classes: 'node-domain'
    })
    cy.add({
        group: 'edges'
        data: {
            source: attr_id
            target: dom_id
        }}
    )

    # male qui
    reshape()
    class_cur_letter += 1
    
    cy.add({
        group: 'nodes'
        data: {id: class_cur_letter}
        classes: 'node-variable'
    })
    cy.add({
        group: 'edges'
        data: {
            source: dom_id
            target: class_cur_letter
        }
    })


compute_distance = (node1, node2) ->
    a = Math.abs(node1.position('x') - node2.position('x'))
    b = Math.abs(node1.position('y') - node2.position('y'))
    return Math.sqrt(a*a + b*b)


check_collisions = ->
    for node in cy.nodes(".node-variable")
        check = false
        for node2 in cy.nodes(".node-variable")
            if node != node2
                if compute_distance(node, node2) < node_base_size
                    node.addClass('highlight')
                    node2.addClass('highlight')
                    return [node, node2]
                else
                    node.removeClass('highlight')

undo = (state_buffer) ->
    if state_buffer == null or state_buffer.length < 1
        console.log "no saved states"
    else
        cy.json(state_buffer[state_buffer.length - 1])
        state_buffer.pop()

save_state = ->
    # state should actually be saved only when the graph is actually modified !!
    if state_buffer == null
        state_buffer = []
    if cy.json() != state_buffer[state_buffer.length - 1]
        state_buffer.push(cy.json())
    if state_buffer.length >= state_buffer_max_length 
       state_buffer.shift() 


merge = (node1, node2) ->
    ###* merges node1 and node2, repositioning all node2's edges into node1 ###
    
    for edge in node2.neighborhood('edge')
    
        # if this edge has node2 as target
        if edge.target().id() == node2.id()
            cy.add({
                group: 'edges'
                data: {
                    source: edge.source().id()
                    target: node1.id()
                }
            })

        # if this edge has node2 as source
        if edge.source().id() == node2.id()
            cy.add({
                group: 'edges'
                data: {
                    source: node1.id()
                    target: edge.target().id()
                }
            })

    # remove node2 with all its connected edges
    cy.remove(node2)


select_node = (node) ->
    if selected_node != null
        selected_node.removeClass('selected')
    selected_node = node
    selected_node.addClass('selected')


cy.on('click', '.node-variable',
    ($) ->
        select_node(this)
        if this.isOrphan()
            add_role(this)
            reshape()
)

cy.on('mousemove',
    ($) ->
        update_sparql_text()
        check_collisions()
)

cy.on('mouseup',
    ($) -> 
        save_state()
        if check_collisions() != undefined
            node_tmp_arr = check_collisions()
            merge(node_tmp_arr[0], node_tmp_arr[1])
    
        reshape()
)

init = ->
    left_panel = document.getElementById("config")
    button = document.createElement('button')
    button.innerHTML = 'undo'
    button.className = 'button'
    button.onclick = ($) -> 
        undo(state_buffer)
    left_panel.append(button)

init()
reshape()
cy.resize()
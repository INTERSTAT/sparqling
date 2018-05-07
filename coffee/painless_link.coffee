#_require constants.coffee

class window.PainlessLink

    constructor: (cy, link_name, link_type, node_var1 = null, node_var2 = null) ->
        @cy         = cy

        @link_name  = link_name
        @link_type  = link_type

        @node_var1  = node_var1
        @node_var2  = node_var2

        @node_quad1 = null
        @node_quad2 = null

        if link_type == 'concept'
            @create_concept()
        else
            @create_link()


    find_new_name: (base_name = null) ->
        if base_name == null
            base_name = "x"

        i = 0
        while @cy.getElementById(base_name + i).length != 0 
            i += 1
        return base_name + i


    create_edge: (node1, node2, classes = null) =>
        return @cy.add({
            group: 'edges'
            data: {source: node1.id(), target: node2.id()}
            classes: classes
        })


    reverse: =>
        ###* can only be applied to non-concept relationships ###
        if @node_quad1.hasClass('node-range') 
            @node_quad1.classes('node-domain')
            @source = @node_var2
            @target = @node_var1
            @node_quad2.classes('node-range')
        else 
            @node_quad1.classes('node-range')
            @node_quad2.classes('node-domain')
            @source = @node_var1
            @target = @node_var2
   

    create_node: (type, label = null) =>

        data = {}

        if type == 'node-variable' 
            label = @find_new_name(label)
            data['id'] = label
            
            if label.length == 2
               data['color'] = '#' + palette[label.slice(-1) % palette.length]
            else data['color'] = '#' + palette[Math.round(Math.random()*100) % palette.length]
        
        if type == 'node-concept' 
            data['label'] = @link_name
        else if type == 'node-attribute' or type == 'node-role'
            data['label'] = label
        else data['label'] = '?' + label
        
        data['links'] = [@]

        return @cy.add({
            group: 'nodes'
            data: data
            classes: type
        })


    delete: =>
        if @node_link != null and @node_link != undefined
            @cy.remove(@node_link)
        if @node_concept != null and @node_concept != undefined
            @cy.remove(@node_concept)
        for node_var in [@node_var1, @node_var2]
            if node_var != null and node_var != undefined
                index = node_var.data('links').indexOf(@)
                node_var.data('links').splice(index, 1)
                if node_var.data('links').length == 0
                    @cy.remove(node_var)



    create_link: =>
        if @node_var1 == null or @node_var1 == undefined
            @node_var1   = @create_node('node-variable')
        else @node_var1.data('links').push(@)

        if @node_var2 == null or @node_var2 == undefined
            if @link_type == 'attribute'
                @node_var2   = @create_node('node-variable', @link_name)
            else @node_var2 = @create_node('node-variable')
        else @node_var2.data('links').push(@)
       
        @source = @node_var1
        @target = @node_var2

        if @link_type == 'role'
            @node_link       = @create_node('node-role', @link_name)
        else
            @node_link       = @create_node('node-attribute', @link_name)

        @create_edge(@source, @node_link, "source-edge")
        @create_edge(@node_link, @target, "target-edge")
       

    create_concept: =>
        if @node_var1 == null
            @node_var1  = @create_node('node-variable')

        @node_concept     = @create_node('node-concept')
        @create_edge(@node_var1, @node_concept)
            




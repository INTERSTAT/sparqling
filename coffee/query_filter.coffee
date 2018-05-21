class window.QueryFilter


    constructor: (node) ->
        
        @node = node

        @conditions = []
        @conditions.push(@new_condition())


    new_condition: () =>
        d = document.createElement('div')
        if @node != undefined
            hl_box = new window.HlBox(@node)
            d.appendChild(hl_box.to_html())
        else
            v = new window.Void
            d.appendChild(v.to_html())

        operator = document.createElement('div')
        operator.innerHTML = ">="
        operator.style.marginLeft = '5px'
        operator.style.marginRight = '5px'

        d.appendChild(operator)

        value = document.createElement('div')
        value.innerHTML = "100 ^^xsd:string"
        value.contentEditable = 'true'

        d.appendChild(value)

        return d



    to_html: =>
        result_div = document.createElement('div')
        
        start = document.createElement('div')
        start.innerHTML = "filter "
        start.style.display = "inline"
        result_div.append(start)

        conditions_container = document.createElement('div')
        conditions_container.className = "filter_condition_container"
        for condition in @conditions
            conditions_container.appendChild(condition)
        result_div.append(conditions_container)

        remove_button = document.createElement('div')
        remove_button.innerHTML = '❎'
        remove_button.style.color = '#F08080'
        remove_button.style.fontSize = 'large'
        remove_button.style.marginLeft = '8px'
        remove_button.style.visibility = 'hidden'
        remove_button.style.display = 'inline-block'
        remove_button.onclick = () =>
            console.log 'click'
        result_div.append(remove_button)

        result_div.onmouseover = () =>
            remove_button.style.visibility = 'visible'
        result_div.onmouseout = () =>
            remove_button.style.visibility = 'hidden'
            

        return result_div

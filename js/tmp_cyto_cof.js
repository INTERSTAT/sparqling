// Generated by CoffeeScript 1.12.7
(function() {
  var cy, elements, randomize, reshape, sparql_text;

  console.log("start");

  sparql_text = document.getElementById("sparql_text");

  elements = {
    nodes: [
      {
        data: {
          id: 'a'
        }
      }, {
        data: {
          id: 'b'
        }
      }, {
        data: {
          id: 'c',
          parent: 'a'
        },
        classes: "node-domain"
      }, {
        data: {
          id: 'd'
        }
      }
    ],
    edges: [
      {
        data: {
          id: 'ab',
          source: 'a',
          target: 'b'
        }
      }
    ]
  };

  cy = new cytoscape({
    container: document.getElementById('cy'),
    elements: elements,
    style: new cytoscape.stylesheet().selector('node').style({
      'background-color': 'black',
      'shape': 'rectangle',
      'content': 'data(id)'
    }).selector('.node-domain').style({
      'background-color': 'white',
      'border-color': 'black',
      'border-style': 'solid',
      'border-width': '2px'
    }).selector('.node-attribute').style({
      'shape': 'ellipse',
      'background-color': 'white',
      'border-style': 'solid',
      'border-color': 'black',
      'border-width': '2px'
    }).selector(':parent').style({
      'background-image': 'resources/background-circle.png',
      'background-opacity': '0',
      'shape': 'rectangle',
      'border-color': 'white'
    })
  });

  reshape = function() {
    var child, j, len, neighbor, parent, parents, results;
    parents = cy.nodes().parents();
    results = [];
    for (j = 0, len = parents.length; j < len; j++) {
      parent = parents[j];
      parent.position({
        x: 0,
        y: 0
      });
      parent.children().layout({
        name: 'circle'
      }).run();
      results.push((function() {
        var k, len1, ref, results1;
        ref = parent.children();
        results1 = [];
        for (k = 0, len1 = ref.length; k < len1; k++) {
          child = ref[k];
          results1.push((function() {
            var l, len2, ref1, results2;
            ref1 = child.neighborhood('node');
            results2 = [];
            for (l = 0, len2 = ref1.length; l < len2; l++) {
              neighbor = ref1[l];
              console.log(neighbor);
              neighbor.position('x', child.position('x') + Math.cos(child.position('x') - parent.position('x')) * 100);
              results2.push(neighbor.position('y', child.position('y') + Math.sin(child.position('y') - parent.position('y')) * 100));
            }
            return results2;
          })());
        }
        return results1;
      })());
    }
    return results;
  };

  randomize = function(parent_name) {
    var i, j, new_node_2_id, new_node_id, range, ref, results;
    range = Math.random() * (15 - 5);
    results = [];
    for (i = j = 0, ref = range - 1; j < ref; i = j += 1) {
      new_node_id = parent_name + Math.round(Math.random() * 1000);
      new_node_2_id = parent_name + Math.round(Math.random() * 1000);
      cy.add({
        group: 'nodes',
        data: {
          id: new_node_id,
          parent: parent_name
        }
      });
      cy.add({
        group: 'nodes',
        data: {
          id: new_node_2_id
        },
        classes: 'node-attribute'
      });
      cy.add({
        group: 'edges',
        data: {
          source: new_node_id,
          target: new_node_2_id
        }
      });
      results.push(reshape());
    }
    return results;
  };

  cy.on('click', ':parent', function($) {
    cy.add({
      group: 'nodes',
      data: {
        id: this.id() + Math.round(Math.random() * 1000),
        parent: this.id()
      }
    });
    return reshape();
  });

  cy.on('mousemove', function($) {
    var child, j, k, len, len1, parent, ref, ref1, sparql_string;
    sparql_string = "Select * <br> where { <br>";
    ref = cy.nodes().parents();
    for (j = 0, len = ref.length; j < len; j++) {
      parent = ref[j];
      ref1 = parent.children();
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        child = ref1[k];
        sparql_string += "&emsp;$" + parent.id() + " " + child.id() + "<br>";
      }
    }
    return sparql_text.innerHTML = sparql_string + "}";
  });

  randomize('a');

  reshape();

}).call(this);
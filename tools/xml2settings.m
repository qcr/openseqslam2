function s = xml2settings(xmlLocation)
    % Extract the doc model from the XML file
    doc = xmlread(xmlLocation);

    % Get the root node (which corresponds to the struct)
    root = doc.getDocumentElement();

    % Recursively loop through each of the elements, adding them to the
    % settings struct
    s = readRecursive(root, emptyConfig());

    function s = readRecursive(currentNode, existing)
        % Start with the existing struct
        s = existing;

        % Loop over all elements contained in the root node
        % NOTE: we 0 index here, because it is acually Java function calls we
        % are making...................... cheers for that mess MATLAB....
        es = currentNode.getChildNodes();
        for k = 0:es.getLength()-1
            % Skip if it is not an element node (don't want to directly deal
            % with text nodes, attribute nodes, comment nodes, etc...)
            if es.item(k).getNodeType() ~= ...
                    org.apache.xerces.dom.DeferredElementImpl.ELEMENT_NODE
                continue;
            end
            
            % Get the value
            if strcmpi(es.item(k).getTagName(), 'settings-group')
                v = readRecursive(es.item(k), ...
                    s.(char(es.item(k).getAttribute('name'))));
            elseif strcmpi(es.item(k).getAttribute('type'), 'numeric')
                v = str2num(char(es.item(k).getAttribute('value')));
            elseif strcmpi(es.item(k).getAttribute('type'), 'boolean')
                v = logical(char(es.item(k).getAttribute('value')));
            elseif strcmpi(es.item(k).getAttribute('type'), 'string')
                v = char(es.item(k).getAttribute('value'));
            elseif strcmpi(es.item(k).getAttribute('type'), 'vector')
                v = SafeData.str2vector( ...
                    char(es.item(k).getAttribute('value')));
            else
                v = []; % Failed to read.... let's just set it as empty...
            end
            s.(char(es.item(k).getAttribute('name'))) = v;
        end
    end
end

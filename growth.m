function g = growth(x)
    
    g = (x(2:end)-x(1:end-1))./x(1:end-1);

end
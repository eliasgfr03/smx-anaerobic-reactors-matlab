function yNew=CS_conservative_remap(yOld,oldN,newN)
Wold=yOld(1:2:end); Told=yOld(2:2:end); Wnew=remap(Wold,oldN,newN); Tnew=remap(Told,oldN,newN); yNew=zeros(2*newN,1); yNew(1:2:end)=Wnew; yNew(2:2:end)=Tnew;
end
function cNew=remap(cOld,oldN,newN)
oe=linspace(0,1,oldN+1); ne=linspace(0,1,newN+1); cNew=zeros(newN,1);
for j=1:newN; a=ne(j); b=ne(j+1); acc=0; for k=1:oldN; ov=max(0,min(b,oe(k+1))-max(a,oe(k))); acc=acc+ov*cOld(k); end; cNew(j)=acc/(b-a); end
end
